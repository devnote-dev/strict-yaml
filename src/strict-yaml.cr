require "./strict-yaml/*"

module StrictYAML
  VERSION = "0.1.0"

  def self.parse(source : String) : Any
    parse_all(source).first
  end

  def self.parse_all(source : String) : Array(Any)
    parse_documents(source).group_by(&.nodes).keys.map do |nodes|
      case nodes[0]
      when List
        Any.new nodes.map { |n| n.object }
      when Mapping
        hash = nodes.map(&.object).reduce({} of Any => Any) do |acc, i|
          acc.merge i.as(Hash(Any, Any))
        end

        Any.new hash
      else
        Any.new nodes[0].object
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
