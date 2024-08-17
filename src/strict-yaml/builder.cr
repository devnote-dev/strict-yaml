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

    def initialize(@io : IO, @nodes : Array(Node) = [] of Node)
      @type = :none
    end

    def directive(value : String) : Nil
      @nodes << Directive.new value
    end

    def document_start : Nil
      @nodes << DocumentStart.new
    end

    def document_end : Nil
      @nodes << DocumentEnd.new
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

      nodes = nodes.in_groups_of 2
      # TODO: figure out the rest of this
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
      @nodes.each &->write(Node)
      @io.flush
    end

    private def write(node : Directive) : Nil
      io << '%' << node.value
    end

    private def write(node : DocumentStart) : Nil
      io << "---"
    end

    private def write(node : DocumentEnd) : Nil
      io << "..."
    end

    private def write(node : Scalar) : Nil
      io << node.value
    end

    private def write(node : Boolean) : Nil
      io << ndoe.value
    end

    private def write(node : Null) : Nil
      io << "null"
    end

    private def write(node : Mapping) : Nil
    end

    private def write(node : List) : Nil
    end

    private def write(node : Space) : Nil
      @io << node.value
    end

    private def write(node : Newline) : Nil
      @io << node.value
    end
  end
end
