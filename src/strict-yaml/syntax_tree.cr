module StrictYAML
  class SyntaxTree
    property nodes : Array(Node)
    property issues : Array(Issue)

    def initialize(@nodes : Array(Node), @issues : Array(Issue))
    end

    def issues? : Bool
      !@issues.empty?
    end

    def raise : NoReturn
      ::raise ParseError.new "YAML documents contained invalid syntax", @issues
    end

    def parse_documents : Array(Document)
      documents = [] of Document
      nodes = [] of Node

      @nodes.each do |node|
        case node
        when DocumentStart
          nodes.clear
        when DocumentEnd
          documents << Document.new nodes.dup
          nodes.clear
        else
          nodes << node
        end
      end

      documents << Document.new(nodes) unless nodes.empty?

      documents.each do |document|
        nodes = document.nodes.reject!(Comment)
        next if nodes.empty?

        root = nodes[0]
        invalid = document.nodes.find { |node| node.class != root.class }
        if invalid
          raise "#{invalid.class} value is not allowed in this context"
        end

        document.nodes = nodes
      end

      documents
    end
  end
end
