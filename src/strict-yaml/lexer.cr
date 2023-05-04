module StrictYAML
  class Token
    enum Type
      String
      Colon
      Pipe
      PipeKeep
      PipeStrip
      Fold
      FoldKeep
      FoldStrip
      List
      DocumentStart
      DocumentEnd
      Comment
      Directive

      Space
      Newline
      EOF
    end

    property type : Type
    property value : String
    getter pos : Position

    def initialize(line : Int32, column : Int32)
      @type = :eof
      @value = ""
      @pos = Position.new line, column
    end
  end

  class Lexer
    getter source : String
    @reader : Char::Reader
    @line : Int32
    @token : Token

    def initialize(@source : String)
      @reader = Char::Reader.new source
      @line = 0
      @token = uninitialized Token
    end

    def run : Array(Token)
      tokens = [] of Token

      loop do
        next_token
        tokens << @token
        break if @token.type.eof?
      end

      tokens
    end

    private def next_token : Nil
      @token = Token.new @line, @reader.pos

      case current_char
      when '\0'
        finalize_token false
      when ' '
        lex_space
      when '\r', '\n'
        lex_newline
      when ':'
        next_char
        @token.type = :colon
        finalize_token true
      when '|'
        case next_char
        when '+'
          next_char
          @token.type = :pipe_keep
        when '-'
          next_char
          @token.type = :pipe_strip
        else
          @token.type = :pipe
        end
        finalize_token true
      when '>'
        case next_char
        when '+'
          next_char
          @token.type = :fold_keep
        when '-'
          next_char
          @token.type = :fold_strip
        else
          @token.type = :fold
        end
        finalize_token true
      when '-'
        if next_char == '-' && next_char == '-'
          next_char
          @token.type = :document_start
        else
          @token.type = :list
        end
        finalize_token true
      when '.'
        if next_char == '.' && next_char == '.'
          next_char
          @token.type = :document_end
          finalize_token true
        else
          lex_string
        end
      when '#'
        lex_comment
      when '%'
        lex_directive
      else
        lex_string
      end
    end

    private def finalize_token(with_value : Bool) : Nil
      @token.pos.line_stop = @line
      @token.pos.column_stop = @reader.pos

      if with_value
        @token.value = @source[@token.pos.column_start...@token.pos.column_stop]
      end
    end

    private def current_char : Char
      @reader.current_char
    end

    private def next_char : Char
      @reader.next_char
    end

    private def lex_space : Nil
      while current_char == ' '
        next_char
      end

      @token.type = :space
      finalize_token true
    end

    private def lex_newline : Nil
      loop do
        case current_char
        when '\r'
          raise "expected '\\n' after '\\r'" unless next_char == '\n'
          @line += 1
        when '\n'
          @line += 1
        else
          break
        end

        next_char
      end

      @token.type = :newline
      finalize_token true
    end

    private def lex_string : Nil
      until current_char.in?('\0', '\r', '\n', ':', '#')
        next_char
      end

      @token.type = :string
      finalize_token true
    end

    private def lex_comment : Nil
      until current_char.in?('\0', '\r', '\n')
        next_char
      end

      @token.pos.column_start += 1
      @token.type = :comment
      finalize_token true
    end

    private def lex_directive : Nil
      until current_char.in?('\0', '\r', '\n')
        next_char
      end

      @token.pos.column_start += 1
      @token.type = :directive
      finalize_token true
    end
  end
end
