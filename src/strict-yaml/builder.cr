module StrictYAML
  class Builder
    private enum CoreType
      None
      Scalar
      Mapping
      List
    end

    private class NullWriter < IO
      def read(slice : Bytes) : Nil
      end

      def write(slice : Bytes) : Nil
      end
    end

    @io : IO
    @type : CoreType
    @nodes : Array(Node)
    @indent : Int32

    def initialize(@io : IO, @nodes : Array(Node) = [] of Node)
      @type = :none
      @indent = 0
    end

    def directive(value : String) : Nil
      @nodes << Directive.new value
    end

    def document_start : Nil
      @nodes << DocumentStart.new << Newline.new "\n"
    end

    def document_end : Nil
      @nodes << DocumentEnd.new << Newline.new "\n"
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

    def mapping(& : Builder -> _) : Nil
      builder = Builder.new NullWriter.new
      with builder yield builder

      nodes = builder.@nodes
      raise "invalid key-value mapping pairs" unless nodes.size % 2 == 0

      nodes.in_groups_of(2).each do |(key, value)|
        @nodes << Mapping.new key.as(Node), [value.as(Node)]
      end
    end

    def list(& : Builder -> _) : Nil
      builder = Builder.new NullWriter.new
      with builder yield builder

      @nodes << List.new builder.@nodes
    end

    def comment(value : String) : Nil
      @nodes << Comment.new value
    end

    def newline : Nil
      @nodes << Newline.new "\n"
    end

    def close : Nil
      @nodes.each do |node|
        check_indent
        write node
      end
      @io.flush
    end

    private def check_indent : Nil
      @io << " " * @indent unless @indent == 0
    end

    private def write(node : Space) : Nil
      @io << node.value
    end

    private def write(node : Newline) : Nil
      @io << node.value
    end

    private def write(node : Scalar) : Nil
      @io << node.value
    end

    private def write(node : Boolean) : Nil
      @io << node.value
    end

    private def write(node : Null) : Nil
      @io << "null"
    end

    private def write(node : Mapping) : Nil
      write node.key
      @io << ':'

      if node.values.size == 1
        if node.values[0].is_a?(List)
          @io << '\n'
          write node.values[0]
        else
          @io << ' '
          write node.values[0]
          @io << '\n'
        end
      else
        @io << '\n'
        @indent += 1

        node.values.each do |value|
          check_indent
          write value
        end

        @indent -= 1
        @io << '\n'
      end
    end

    private def write(node : List) : Nil
      @indent += 1

      node.values.each do |value|
        check_indent
        @io << "- "
        write value
        @io << '\n'
      end

      @indent -= 1
    end

    private def write(node : DocumentStart) : Nil
      @io << "---\n"
    end

    private def write(node : DocumentEnd) : Nil
      @io << "...\n"
    end

    private def write(node : Comment) : Nil
      check_indent
      node.value.each_line do |line|
        @io << "# " << line << '\n'
      end
    end

    private def write(node : Directive) : Nil
      @io << '%' << node.value
    end

    private def write(node : Node) : Nil
    end
  end
end
