class Object
  def self.from_strict_yaml(source : String)
    new StrictYAML.parse source
  end

  def self.from_strict_yaml(value : StrictYAML::Any)
    new value
  end

  def to_strict_yaml : String
    String.build do |io|
      to_strict_yaml io
    end
  end

  def to_strict_yaml(io : IO) : Nil
    builder = StrictYAML::Builder.new io
    to_strict_yaml builder
    builder.close
  end
end

struct Nil
  def self.new(value : StrictYAML::Any)
    nil
  end

  def to_strict_yaml(yaml : StrictYAML::Builder) : Nil
    yaml.null
  end
end

{% for base in %w[8 16 32 64 128] %}
  struct Int{{ base.id }}
    def self.new(value : StrictYAML::Any)
      value.to_i{{ base.id }}
    end

    def to_strict_yaml(yaml : StrictYAML::Builder) : Nil
      yaml.scalar self
    end
  end
{% end %}

{% for base in %w[32 64] %}
  struct Float{{ base.id }}
    def self.new(value : StrictYAML::Any)
      value.to_f{{ base.id }}
    end

    def to_strict_yaml(yaml : StrictYAML::Builder) : Nil
      yaml.scalar self
    end
  end
{% end %}

class String
  def self.new(value : StrictYAML::Any)
    value.as_s
  end

  def to_strict_yaml(yaml : StrictYAML::Builder) : Nil
    yaml.scalar self
  end
end

struct Bool
  def self.new(value : StrictYAML::Any)
    value.as_bool
  end

  def to_strict_yaml(yaml : StrictYAML::Builder) : Nil
    yaml.boolean self
  end
end

struct Char
  def self.new(value : StrictYAML::Any)
    chars = value.as_s.chars
    raise "invalid character sequence" unless chars.size == 1
    chars[0]
  end

  def to_strict_yaml(yaml : StrictYAML::Builder) : Nil
    yaml.scalar self
  end
end

struct Path
  def self.new(value : StrictYAML::Any)
    new value.as_s
  end

  def to_strict_yaml(yaml : StrictYAML::Builder) : Nil
    yaml.scalar self
  end
end

class Array(T)
  def self.new(value : StrictYAML::Any)
    arr = new
    value.as_a.each do |child|
      arr << T.new child
    end
    arr
  end

  def to_strict_yaml(yaml : StrictYAML::Builder) : Nil
    yaml.list do |list|
      each &.to_strict_yaml list
    end
  end
end

class Deque(T)
  def self.new(value : StrictYAML::Any)
    deq = new
    value.as_a.each do |child|
      deq << T.new child
    end
    deq
  end

  def to_strict_yaml(yaml : StrictYAML::Builder) : Nil
    yaml.list do |list|
      each &.to_strict_yaml list
    end
  end
end

struct Set(T)
  def self.new(value : StrictYAML::Any)
    set = new
    value.as_a.each do |child|
      set << T.new child
    end
    set
  end

  def to_strict_yaml(yaml : StrictYAML::Builder) : Nil
    yaml.list do |list|
      each &.to_strict_yaml list
    end
  end
end

struct Tuple(*T)
  def self.new(value : StrictYAML::Any)
    {% begin %}
      arr = value.as_a
      new(
        {% for i in 0...T.size %}
          (self[{{ i }}].new arr[{{ i }}]),
        {% end %}
      )
    {% end %}
  end

  def to_strict_yaml(yaml : StrictYAML::Builder) : Nil
    yaml.list do |list|
      each &.to_strict_yaml list
    end
  end
end

class Hash(K, V)
  def self.new(value : StrictYAML::Any)
    hash = new
    value.as_h.each do |k, v|
      hash[K.new(k)] = V.new(v)
    end
    hash
  end

  def to_strict_yaml(yaml : StrictYAML::Builder) : Nil
    yaml.mapping do |m|
      each do |key, value|
        m.scalar key
        m.scalar value
        m.newline
      end
    end
  end
end

struct NamedTuple
  def self.new(value : StrictYAML::Any)
    {% begin %}
      {% for key, type in T %}
        {% if type.nilable? %}
          %var{key.id} = nil
        {% else %}
          %var{key.id} = uninitialized {{ type }}
        {% end %}
        %found{key.id} = false
      {% end %}

      value.as_h.each do |k, v|
        case k.as_s
        {% for key, type in T %}
          when {{ key.stringify }}
            %var{key.id} = {{ type }}.from_strict_yaml v
            %found{key.id} = true
        {% end %}
        end
      end

      {% for key, type in T %}
        {% unless type.nilable? %}
          unless %found{key.id}
            raise "missing YAML attribute: {{ key.id }}"
          end
        {% end %}
      {% end %}

      new(
        {% for key in T.keys %}
          {{ key.id.stringify }}: %var{key.id},
        {% end %}
      )
    {% end %}
  end

  def to_strict_yaml(yaml : StrictYAML::Builder) : Nil
    yaml.mapping do |m|
      each do |key, value|
        m.scalar key
        m.scalar value
        m.newline
      end
    end
  end
end

struct Enum
  def self.new(value : StrictYAML::Any)
    {% if @type.annotation(Flags) %}
      case value.raw
      when String
        parse?(value.as_s) || raise "unknown enum #{self} value: #{value.as_s.inspect}"
      when Array
        data = {{ @type }}::None
        value.as_a.each do |item|
          data |= parse?(item.as_s) || raise "unknown enum #{self} value: #{item.as_s.inspect}"
        end
        data
      else
        raise "cannot parse enum from type #{value.raw.class}"
      end
    {% else %}
      parse?(value.as_s) || raise "unknown enum #{self} value: #{value.as_s.inspect}"
    {% end %}
  end

  def to_strict_yaml(yaml : StrictYAML::Builder) : Nil
    yaml.scalar value
  end
end

struct Union(*T)
  def self.new(value : StrictYAML::Any)
    {% begin %}
      {% for type in T %}
        {% if Number::Primitive.union_types.includes?(type) %}
          return {{ type }}.new value
        {% elsif type == String %}
          return value.as_s
        {% elsif type == Bool %}
          return value.as_bool
        {% end %}
      {% end %}

      {% primitives = [Nil, String, Bool] + Number::Primitive.union_types %}
      {% others = T.reject { |t| primitives.includes?(t) } %}
      {% for type in others %}
        begin
          return {{ type }}.from_strict_yaml value
        rescue StrictYAML::ParseError
        end
      {% end %}

      {% if T.includes?(Nil) %}
        return nil
      {% else %}
        raise StrictYAML::ParseError.new "could not parse #{self} from '#{value}'"
      {% end %}
    {% end %}
  end
end
