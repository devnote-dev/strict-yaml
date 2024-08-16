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
  end
end
