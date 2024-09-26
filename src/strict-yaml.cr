require "./strict-yaml/*"

module StrictYAML
  VERSION = "0.1.0"

  def self.parse(source : String) : Any
    parse_document(source).to_any
  end

  def self.parse_all(source : String) : Array(Any)
    parse_documents(source).map(&.to_any)
  end

  def self.parse_document(source : String, preserve : Bool = false) : Document
    parse_documents(source, preserve)[0]
  end

  def self.parse_documents(source : String, preserve : Bool = false) : Array(Document)
    tokens = Lexer.run source
    Parser.parse(tokens, preserve: preserve).documents
  end
end
