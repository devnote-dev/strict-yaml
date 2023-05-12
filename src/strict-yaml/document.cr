module StrictYAML
  class Document
    property version : String
    property nodes : Array(Node)

    def initialize(@nodes : Array(Node))
      @version = "1.2"

      return unless dir = @nodes.first.as? Directive
      return unless dir.value.starts_with? "YAML "

      @version = dir.value.split(' ', 2).last
      @nodes.shift
    end
  end
end
