module StrictYAML
  class Builder
    @nodes : Array(Node)
    @io : IO
    getter? closed : Bool

    def initialize(@io : IO)
      @nodes = [] of Node
      @closed = false
    end

    def document(& : ->) : Nil
      document_start
      yield
      document_end
    end

    def document_start : Nil
      @nodes << DocumentStart.empty
    end

    def document_end : Nil
      @nodes << DocumentEnd.empty
    end

    def scalar(value : _) : Nil
      @nodes << Scalar.new value.to_s
    end

    def boolean(value : Bool) : Nil
      @nodes << Boolean.new value
    end

    def null : Nil
      @nodes << Null.empty
    end

    def mapping(key : K, value : V) : Nil forall K, V
      {% begin %}
        {% if K == String || K < Number::Primitive %}
          key = Scalar.parse key.to_s
        {% elsif K == Bool %}
          key = Boolean.new key
        {% elsif K == Nil %}
          key = Null.empty
        {% else %}
          {% raise "unsupported YAML key type #{K}" %}
        {% end %}

        {% if V == String || V < Number::Primitive %}
          value = Scalar.parse value.to_s
        {% elsif V == Bool %}
          value = Boolean.new value
        {% elsif V == Nil %}
          value = Null.empty
        {% else %} # TODO: handle array & hash types
          {% raise "unsupported YAML value type #{V}" %}
        {% end %}

        @nodes << Mapping.new key, value
      {% end %}
    end

    def mapping(key : K, & : ->) : Nil forall K
      {% begin %}
        {% if K == String || K < Number::Primitive %}
          key = Scalar.parse key.to_s
        {% elsif K == Bool %}
          key = Boolean.new key
        {% elsif K == Nil %}
          key = Null.empty
        {% else %}
          {% raise "unsupported YAML key type #{K}" %}
        {% end %}
      {% end %}

      original = @nodes.dup
      @nodes.clear
      yield

      values = @nodes
      @nodes = original
      value = values.size > 1 ? List.new(values) : values[0]

      @nodes << Mapping.new key, value
    end

    def list(& : ->) : Nil
      original = @nodes.dup
      @nodes.clear
      yield

      values = @nodes
      @nodes = original
      @nodes << List.new values
    end

    def comment(text : String) : Nil
      @nodes << Comment.new text
    end

    def close : Nil
      return if @closed

      @nodes.each_with_index do |node, index|
        visit node
        unless @nodes[index + 1]?.is_a? Comment
          @io << '\n'
        end
      end

      @closed = true
      @io.flush
    end

    private def visit(node : DocumentStart) : Nil
      @io << "---"
    end

    private def visit(node : DocumentEnd) : Nil
      @io << "..."
    end

    private def visit(node : Scalar) : Nil
      @io << node.value
    end

    private def visit(node : Boolean) : Nil
      @io << node.value
    end

    private def visit(node : Null) : Nil
      @io << "null"
    end

    private def visit(node : Mapping) : Nil
      visit node.key
      @io << ':'
      if node.value.is_a?(Mapping | List)
        @io << '\n'
      else
        @io << ' '
      end
      visit node.value
    end

    private def visit(node : List) : Nil
      node.values.each do |value|
        @io << "- "
        visit value
        @io << '\n'
      end
    end

    private def visit(node : Comment) : Nil
      @io << "  # " << node.value << '\n'
    end

    private def visit(node : Node) : Nil
    end
  end
end
