require "./strict-yaml/*"

module StrictYAML
  VERSION = "0.1.0"

  def self.parse(source : String) : Any
    parse_all(source).first
  end

  def self.parse_all(source : String) : Array(Any)
    parse_documents(source).map do |document|
      case nodes = document.nodes
      when Array(List)
        Any.new nodes.map &.object
      when Array(Mapping)
        Any.new nodes.map(&.object).reduce { |acc, i| acc.merge i }
      else
        Any.new nodes.first.object
      end
    end
  end

  def self.parse_document(source : String) : Document
    parse_documents(source).first
  end

  def self.parse_documents(source : String) : Array(Document)
    tokens = Lexer.new(source).run
    Parser.new(tokens).parse_documents
  end
end
