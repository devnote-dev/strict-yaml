module StrictYAML
  class Document
    VERSIONS = {"1.0", "1.1", "1.2"}

    property version : String
    property nodes : Array(Node)

    def initialize(@nodes : Array(Node))
      @version = "1.2"

      return unless dir = @nodes.first.as? Directive
      return unless dir.value.starts_with? "YAML "

      version = dir.value.split(' ', 2).last
      raise "invalid YAML version" unless VERSIONS.includes? version

      @version = version
      @nodes.shift
    end
  end
end
