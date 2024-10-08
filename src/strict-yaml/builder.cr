module StrictYAML
  class Builder
    private class NullWriter < IO
      def read(slice : Bytes) : Nil
      end

      def write(slice : Bytes) : Nil
      end
    end

    private NULL = NullWriter.new

    @io : IO
    @indent : Int32
    @nodes : Array(Node)

    def self.build(&block : Builder -> _) : String
      String.build do |io|
        build(io, &block)
      end
    end

    def self.build(io : IO, & : Builder -> _) : Nil
      builder = new io
      with builder yield builder
      builder.close
    end

    # :nodoc:
    def initialize(@io : IO, @indent : Int32 = 0, @nodes : Array(Node) = [] of Node)
    end

    def directive(value : String) : Nil
      @nodes << Directive.new(value) << Newline.new("\n")
    end

    def document(directive value : String? = nil, & : Builder -> _) : Nil
      directive value if value
      document_start

      builder = Builder.new NULL
      with builder yield builder

      @nodes.concat builder.@nodes
      document_end
    end

    def document_start : Nil
      @nodes << DocumentStart.empty << Newline.new("\n")
    end

    def document_end : Nil
      @nodes << DocumentEnd.empty << Newline.new("\n")
    end

    def scalar(value : _) : Nil
      @nodes << Scalar.new(value.to_s) << Newline.new("\n")
    end

    def boolean(value : Bool) : Nil
      @nodes << Boolean.new(value) << Newline.new("\n")
    end

    def null : Nil
      @nodes << Null.empty << Newline.new("\n")
    end

    def mapping(& : Builder -> _) : Nil
      check_indent
      builder = Builder.new NULL, @indent + 2
      with builder yield builder

      nodes = builder.@nodes
      key : Node? = nil
      values = [] of Node
      i = 0

      loop do
        case node = nodes[i]?
        when Nil, Directive, DocumentStart, DocumentEnd
          if key
            raise "invalid key-value mapping pairs"
          end
          break
        when Space
          values << node
          i += 1
        when Newline, Comment
          @nodes << node
          i += 1
        else
          if key
            if node.is_a?(Mapping) || node.is_a?(List)
              values.unshift Newline.new "\n"
              @nodes << Mapping.new key, values << node
            else
              values.unshift Space.new " "
              @nodes << Mapping.new key, values << node

              if nodes[i + 1]?.as?(Newline)
                i += 1
              end
            end
            key = nil
            values = [] of Node
          else
            key = node
            if nodes[i + 1]?.as?(Newline)
              i += 1
            end
          end
          i += 1
        end
      end
    end

    def list(& : Builder -> _) : Nil
      # check_indent
      builder = Builder.new NULL, @indent + 2
      with builder yield builder

      nodes = builder.@nodes.flat_map { |n| [Space.new(" "), n] }
      @nodes << List.new nodes
    end

    def comment(value : String) : Nil
      check_indent
      @nodes << Comment.new(value) << Newline.new("\n")
    end

    def newline : Nil
      @nodes << Newline.new "\n"
    end

    def close : Nil
      @nodes.each do |node|
        write node
      end
      @io.flush
    end

    private def check_indent : Nil
      unless @indent == 0
        @nodes << Space.new " " * @indent
      end
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
        write value
      end
    end

    private def write(node : List) : Nil
      @io << '-'
      i = 0
      loop do
        case inner = node.values[i]?
        when Nil
          break
        when Newline
          write inner
          @io << '-' if node.values[i += 1]?
        else
          write inner
          i += 1
        end
      end
    end

    private def write(node : DocumentStart) : Nil
      @io << "---"
    end

    private def write(node : DocumentEnd) : Nil
      @io << "..."
    end

    private def write(node : Comment) : Nil
      node.value.each_line do |line|
        @io << "# " << line << '\n'
      end
    end

    private def write(node : Directive) : Nil
      @io << '%' << node.value
    end
  end
end
