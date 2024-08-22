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

    def build : Nil
      Formatter.new(@nodes).format.each do |node|
        check_indent
        write node
      end
      @io.flush
    end

    private def check_indent : Nil
      @io << " " * @indent unless @indent == 0
    end

    private def write(node : Space | Newline | Scalar | Boolean) : Nil
      @io << node.value
    end

    private def write(node : Null) : Nil
      @io << "null"
    end

    private def write(node : Mapping) : Nil
      write node.key
      @io << ':'

      node.values.each do |value|
        check_indent
        write value
      end
    end

    private def write(node : List) : Nil
      @indent += 2

      node.values.each do |value|
        check_indent
        @io << "- "
        write value
      end

      @indent -= 2
    end

    private def write(node : DocumentStart) : Nil
      @io << "---"
    end

    private def write(node : DocumentEnd) : Nil
      @io << "..."
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

    private class Formatter
      @source : Array(Node)
      @pos : Int32

      def initialize(@source : Array(Node))
        @pos = 0
      end

      def format : Array(Node)
        nodes = [] of Node

        while @pos < @source.size
          # case value = format current_node
          # when Array
          #   nodes.concat value
          # else
          #   node << value
          # end
          nodes << format current_node
        end

        nodes
      end

      private def current_node : Node
        @source[@pos]
      end

      private def peek_node : Node
        @source[@pos + 1]
      end

      private def next_node : Node
        @source[@pos += 1]
      end

      # private def format(node : Space | Newline | Scalar | Boolean | Null) : Node
      #   node
      # end

      private def format(node : Mapping) : Node
        iter = node.values.each
        formatted = [] of Node

        loop do
          case value = tap iter.next
          when Iterator::Stop
            unless formatted[-1].is_a?(Newline)
              formatted << Newline.new "\n"
            end
            break
          when Space
            formatted << value
          when Newline
            formatted << value
            # pp! formatted
            # if peek = iter.next.as?(Node)
            #   if peek.is_a?(Space)
            #     formatted << peek
            #   else
            #     formatted << Space.new("  ") << peek
            #   end
            #   iter.next
            # end
          when Scalar | Boolean | Null
            unless formatted[-1].is_a?(Space)
              formatted << Space.new " "
            end

            formatted << value
          when Mapping
            unless formatted[-2].is_a?(Newline)
              formatted << Newline.new "\n"
            end

            unless formatted[-1].is_a?(Space)
              formatted << Space.new "  "
            end

            formatted << format value
          when List
            unless formatted[-2].is_a?(Newline)
              formatted << Newline.new "\n"
            end

            unless formatted[-1].is_a?(Space)
              formatted << Space.new "  "
            end

            formatted << format value
          end
        end

        node.values = formatted

        node
      end

      # TODO
      private def format(node : Node) : Node
        node
      end
    end
  end
end
