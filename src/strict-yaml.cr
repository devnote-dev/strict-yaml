require "./strict-yaml/*"

module StrictYAML
  VERSION = "0.1.0"

  def self.parse(source : String) : Any
    parse_all(source).first
  end

  def self.parse_all(source : String) : Array(Any)
    parse_documents(source).map(&.nodes).map do |nodes|
      case nodes[0]
      when List
        arr = nodes.map(&.to_object).reduce([] of Any) do |acc, i|
          acc + i.as(Array(Any))
        end

        Any.new arr
      when Mapping
        hash = nodes.map(&.to_object).reduce({} of Any => Any) do |acc, i|
          acc.merge i.as(Hash(Any, Any))
        end

        Any.new hash
      else
        Any.new nodes[0].to_object
      end
    end
  end

  def self.parse_document(source : String) : Document
    parse_documents(source).first
  end

  def self.parse_documents(source : String) : Array(Document)
    tokens = Lexer.new(source).run
    ast = Parser.new(tokens).parse
    ast.raise if ast.issues?

    ast.parse_documents
  end
end
