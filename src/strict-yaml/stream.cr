module StrictYAML
  class Stream
    getter documents : Array(Document)
    getter errors : Array(Error)

    # :nodoc:
    def initialize(@documents : Array(Document), @errors : Array(Error))
    end

    def errors? : Bool
      !@errors.empty?
    end
  end
end
