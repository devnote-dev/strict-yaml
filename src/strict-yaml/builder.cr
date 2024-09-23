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
      raise "invalid key-value mapping pairs" unless nodes.size % 2 == 0

      nodes.in_groups_of(2).each do |(key, value)|
        @nodes << Mapping.new key.as(Node), [value.as(Node)]
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
  end
end
