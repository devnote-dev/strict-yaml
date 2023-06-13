module StrictYAML
  class Builder
    alias Type = String | Bool | Nil | Array(Type) | Hash(Type, Type)

    @nodes : Array(Node)
    @io : IO
    getter? closed : Bool

    def initialize(@io : IO)
      @nodes = [] of Node
      @closed = false
    end

    def document(*, version : String? = nil, & : ->) : Nil
      document_start version: version
      yield
      document_end
    end

    def document_start(*, version : String? = nil) : Nil
      unless version.nil?
        @nodes << Directive.new "YAML #{version}"
      end
      @nodes << DocumentStart.empty
    end

    def document_end : Nil
      @nodes << DocumentEnd.empty
    end

    def scalar(value : Type) : Nil
      case value
      when String
        @nodes << Scalar.new value
      when Bool
        @nodes << Boolean.new value
      when Nil
        @nodes << Null.empty
      else
        @nodes << Scalar.new value.to_s
      end
    end

    def mapping(key : Type, value : Type) : Nil
      @nodes << Map.from [Mapping.new(parse(key), parse(value))]
    end

    def mapping(key : Type, & : ->) : Nil
      original = @nodes.dup
      @nodes.clear
      yield
      values = @nodes
      @nodes = original
      value = values.size > 1 ? List.new(values) : values[0]

      @nodes << Map.from [Mapping.new(parse(key), value)]
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

    private def parse(value : Type) : Node
      case value
      in String
        Scalar.new value
      in Bool
        Boolean.new value
      in Nil
        Null.empty
      in Hash
        Map.from value.map { |k, v| Mapping.new parse(k), parse(v) }
      in Array
        List.new value.map { |v| parse(v) }
      end
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

    private def visit(node : Map) : Nil
      node.entries.each do |key, value|
        visit key
        @io << ':'

        if value.is_a?(Map | List)
          @io << '\n'
        else
          @io << ' '
        end

        visit value
        @io << '\n'
      end
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

    private def visit(node : Directive) : Nil
      @io << '%' << node.value
    end

    private def visit(node : Node) : Nil
    end
  end
end
