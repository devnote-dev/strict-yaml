require "spec"
require "../src/strict-yaml"

def parse(source : String, *, sensitive : Bool = false) : Array(StrictYAML::Node)
  StrictYAML.parse_document(source, sensitive: sensitive).nodes
end
