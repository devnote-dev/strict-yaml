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

    def self.build(& : Builder -> _) : String
      String.build do |io|
        build io
      end
    end

    def self.build(io : IO, & : Builder -> _) : Nil
      builder = new io
      with builder yield builder
      builder.close
    end

    def initialize(@io : IO, @nodes : Array(Node) = [] of Node)
      @type = :none
      @indent = 0
    end

    def directive(value : String) : Nil
      @nodes << Directive.new(value) << Newline.new("\n")
    end

    def document(directive value : String? = nil, & : Builder -> _) : Nil
      directive value if value
      document_start

      builder = Builder.new NullWriter.new
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
      builder = Builder.new NullWriter.new
      with builder yield builder

      nodes = builder.@nodes
      key : Node? = nil
      i = 0

      loop do
        case node = nodes[i]?
        when Nil, Directive, DocumentStart, DocumentEnd
          if key
            raise "invalid key-value mapping pairs"
          end
          break
        when Newline, Comment
          @nodes << node
          i += 1
        else
          if key
            if node.is_a?(Mapping) || node.is_a?(List)
              @nodes << Mapping.new key, [node]
            else
              @nodes << Mapping.new key, [Space.new(" "), node]

              if nodes[i + 1]?.as?(Newline)
                i += 1
              end
            end
            key = nil
          else
            key = node
          end
          i += 1
        end
      end
    end

    def list(& : Builder -> _) : Nil
      builder = Builder.new NullWriter.new
      with builder yield builder

      @nodes << List.new(builder.@nodes) << Newline.new("\n")
    end

    def comment(value : String) : Nil
      @nodes << Comment.new(value) << Newline.new("\n")
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
      node.values.each do |value|
        @io << "- " unless value.is_a?(Newline)
        write value
      end
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
  end
end
