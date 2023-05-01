module StrictYAML
  class Document
    property version : String
    property nodes : Array(Node)

    def initialize(@nodes : Array(Node))
      @version = "1.2"

      if dir = @nodes.first.as?(Directive)
        if dir.value.starts_with? "YAML "
          @version = dir.value.split(' ', 2).last
          @nodes.shift
        end
      end
    end
  end
end
