module StrictYAML
  class Document
    property nodes : Array(Node)

    def initialize(@nodes : Array(Node))
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

    def version=(@version : String)
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
      root = values[0]

      values.each do |node|
        unless node.class == root.class
          raise Error.new "#{node.class} value is not allowed in this context", node.loc
        end
      end

      case root
      when Mapping
        hash = values.each_with_object({} of Any => Any) do |n, h|
          h.merge! n.to_object.as(Hash(Any, Any))
        end

        Any.new hash
      when List
        # arr = nodes.map(&.to_object).reduce([] of Any) do |acc, i|
        #   acc + i.as(Array(Any))
        # end

        # Any.new arr
        raise "not implemented"
      else
        Any.new values[0].to_object
      end
    end
  end
end
