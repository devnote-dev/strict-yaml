require "./strict-yaml/*"

module StrictYAML
  VERSION = "0.1.0"

  def self.parse(source : String) : Any
    parse_document(source).to_any
  end

  def self.parse_all(source : String) : Array(Any)
    parse_documents(source).map(&.to_any)
  end

  def self.parse_document(source : String, *, preserve : Bool = false,
                          parse_scalars : Bool = true, sensitive : Bool = false) : Document
    parse_documents(source, preserve: preserve, sensitive: sensitive)[0]
  end

  def self.parse_documents(source : String, *, preserve : Bool = false,
                           parse_scalars : Bool = true, sensitive : Bool = false) : Array(Document)
    tokens = Lexer.run source
    Parser.parse(
      tokens,
      preserve: preserve,
      parse_scalars: parse_scalars,
      sensitive_scalars: sensitive
    ).documents
  end
end
