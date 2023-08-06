module StrictYAML
  module Serializable
    macro included
      def self.new(value : StrictYAML::Any)
        unless value.raw.is_a? Hash
          raise "serialization only supported for mappings"
        end

        instance = allocate
        instance.initialize(__strict_yaml_data: value.as_h)
        GC.add_finalizer(instance) if instance.responds_to?(:finalize)

        instance
      end

      macro inherited
        def self.new(value : StrictYAML::Any)
          new value
        end
      end
    end

    def initialize(*, __strict_yaml_data data : Hash(StrictYAML::Any, StrictYAML::Any))
      {% begin %}
        {% props = {} of Nil => Nil %}
        {% for ivar in @type.instance_vars %}
          {% props[ivar.id] = {
               key:         ivar.id.stringify,
               type:        ivar.type,
               has_default: ivar.has_default_value?,
               default:     ivar.default_value,
             } %}
          %var{ivar.id} = uninitialized {{ ivar.type }}
          %found{ivar.id} = false
        {% end %}

        data.each do |key, value|
          case key.as_s
          {% for name, prop in props %}
            when {{ prop[:key] }}
              %var{name} = {{ prop[:type] }}.from_yaml value
              %found{name} = true
          {% end %}
          else
            # on_unknown_attribute key
          end
        end

        {% for name, prop in props %}
          unless %found{name}
            {% if prop[:has_default] %}
              %var{name} = {{ prop[:default] }}
            {% else %}
              raise "missing YAML attribute: {{ name }}"
            {% end %}
          end
        {% end %}

        {% for name, prop in props %}
          @{{ name }} = %var{name}.as({{ prop[:type] }})
        {% end %}
      {% end %}
    end
  end
end
