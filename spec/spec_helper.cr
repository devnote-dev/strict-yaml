require "spec"
require "../src/strict-yaml"

def parse_nodes(source : String) : Array(StrictYAML::Node)
  tokens = StrictYAML::Lexer.run source
  StrictYAML::Parser.parse(tokens).documents[0].nodes
end
