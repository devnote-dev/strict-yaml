require "string_pool"

module StrictYAML
  class Token
    enum Kind
      EOF
      Space
      Newline
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
    end

    property kind : Kind
    property loc : Location
    @value : String?

    def initialize(@kind : Kind, @loc : Location, @value : String? = nil)
    end

    def value : String
      @value.as(String)
    end

    def value=(@value)
    end
  end

  class Lexer
    @pool : StringPool
    @reader : Char::Reader
    @line : Int32
    @column : Int32
    @loc : Location

    def self.run(source : String) : Array(Token)
      new(source).run
    end

    private def initialize(source : String)
      @pool = StringPool.new
      @reader = Char::Reader.new source
      @line = @column = 0
      @loc = Location[0, 0]
    end

    # :nodoc:
    def run : Array(Token)
      tokens = [] of Token

      loop do
        token = lex_next_token
        tokens << token
        break if token.kind.eof?
      end

      tokens
    end

    private def lex_next_token : Token
      case current_char
      when '\0'
        Token.new :eof, location
      when ' '
        lex_space
      when '\r', '\n'
        lex_newline
      when ':'
        next_char
        Token.new :colon, location
      when '|'
        case next_char
        when '+'
          next_char
          Token.new :pipe_keep, location
        when '-'
          next_char
          Token.new :pipe_strip, location
        else
          Token.new :pipe, location
        end
      when '>'
        case next_char
        when '+'
          next_char
          Token.new :fold_keep, location
        when '-'
          next_char
          Token.new :fold_strip, location
        else
          Token.new :fold, location
        end
      when '-'
        if next_char == '-' && next_char == '-'
          next_char
          Token.new :document_start, location
        else
          Token.new :list, location
        end
      when '.'
        if next_char == '.' && next_char == '.'
          next_char
          Token.new :document_end, location
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

    private def current_char : Char
      @reader.current_char
    end

    private def next_char : Char
      @column += 1
      @reader.next_char
    end

    private def current_pos : Int32
      @reader.pos
    end

    private def location : Location
      loc = @loc.end_at(@line, @column).dup
      @loc.start_at(@line, @column)
      loc
    end

    private def read_string_from(start : Int32) : String
      @pool.get Slice.new(@reader.string.to_unsafe + start, @reader.pos - start)
    end

    private def lex_space : Token
      start = current_pos
      while current_char == ' '
        next_char
      end

      Token.new :space, location, read_string_from start
    end

    private def lex_newline : Token
      start = current_pos

      loop do
        case current_char
        when '\r'
          raise "expected '\\n' after '\\r'" unless next_char == '\n'
          @line += 1
          @column = 0
        when '\n'
          @line += 1
          @column = 0
        else
          break
        end

        next_char
      end

      Token.new :newline, location, read_string_from start
    end

    private def lex_string : Token
      start = current_pos
      until current_char.in?('\0', '\r', '\n', ':', '#')
        next_char
      end

      Token.new :string, location, read_string_from start
    end

    private def lex_comment : Token
      start = current_pos + 1
      until current_char.in?('\0', '\r', '\n')
        next_char
      end

      Token.new :comment, location, read_string_from start
    end

    private def lex_directive : Token
      start = current_pos + 1
      until current_char.in?('\0', '\r', '\n', '#')
        next_char
      end

      Token.new :directive, location, read_string_from start
    end
  end
end
