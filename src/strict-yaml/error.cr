module StrictYAML
  struct Issue
    getter message : String
    getter pos : Position

    def initialize(@message : String, @pos : Position)
    end
  end

  class ParseError < Exception
    getter issues : Array(Issue)

    def self.new(message : String)
      new message, [] of Issue
    end

    def initialize(message : String, @issues : Array(Issue))
      super message
    end
  end
end
