module StrictYAML
  class Document
    enum CoreType
      Invalid
      Scalar
      Mapping
      List
    end

    getter nodes : Array(Node)
    getter core_type : CoreType
    getter? preserved : Bool

    def initialize(@nodes : Array(Node), @preserved : Bool)
      @core_type = :invalid
    end

    def version : String
      @version ||= begin
        if dir = @nodes[0].as?(Directive)
          if dir.value.starts_with? "YAML "
            dir.value.split(' ', 2).last
          else
            "1.2"
          end
        else
          "1.2"
        end
      end
    end

    # :nodoc:
    def version=(@version : String)
    end

    # :nodoc:
    def core_type=(@core_type : CoreType)
    end

    def to_any : Any
      values = @nodes.select do |node|
        case node
        when Comment, Directive, DocumentStart, DocumentEnd
          false
        else
          true
        end
      end

      case values[0]
      when Mapping
        hash = values.each_with_object({} of Any => Any) do |n, h|
          h.merge! n.to_object.as(Hash(Any, Any))
        end

        Any.new hash
      when List
        arr = values.each_with_object([] of Any) do |n, a|
          a.concat n.to_object.as(Array(Any))
        end

        Any.new arr
      else
        Any.new values[0].to_object
      end
    end

    def to_s(io : IO) : Nil
      Builder.new(io, nodes: @nodes).close
    end
  end
end
