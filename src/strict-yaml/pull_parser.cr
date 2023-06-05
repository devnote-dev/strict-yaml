module StrictYAML
  class PullParser
    @[Flags]
    enum Kind
      StreamStart
      StreamEnd
      DocumentStart
      DocumentEnd
      Scalar
      Boolean
      Null
      MappingStart
      MappingEnd
      ListStart
      ListEnd
      Comment
      Directive
    end

    getter kind : Kind
    @tokens : Array(Token)
    @prev : Token?

    def initialize(input : String)
      @kind = :stream_start
      @tokens = Lexer.new(input).run
    end

    def read(expected : Kind) : Kind
      expect expected
      @event &= ~expected
      read_next
    end

    def read_next : Kind
      token = @prev = @tokens.shift

      case token.type
      in .string?, .pipe?, .pipe_keep?, .pipe_strip?, .fold?, .fold_keep?, .fold_strip?
        @kind |= :scalar
      in .colon?
        @kind |= :mapping_start
      in .list?
        @kind |= :list_start
      in .document_start?
        @kind |= :document_start
      in .document_end?
        @kind |= :document_end
      in .comment?
        @kind |= :comment
      in .directive?
        @kind |= :directive
      in .space?, .newline?
        @kind
      in .eof?
        @kind = Event::DocumentEnd | Event::StreamEnd
      end

      @kind
    end
  end
end
