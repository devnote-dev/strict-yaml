require "./strict-yaml/*"

module StrictYAML
  VERSION = "0.1.0"

  def self.parse(source : String) : Document
    tokens = Lexer.new(source).run
    Parser.new(tokens).parse_document
  end

  def self.parse_all(source : String) : Array(Document)
    tokens = Lexer.new(source).run
    Parser.new(tokens).parse_documents
  end
end
