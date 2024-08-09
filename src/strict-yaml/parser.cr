module StrictYAML
  class Error < Exception
    getter loc : Location

    def initialize(@message : String, @loc : Location)
    end

    def message : String
      super.as(String)
    end
  end

  class Parser
    @allow_invalid : Bool
    @errors : Array(Error)
    @tokens : Array(Token)
    @pos : Int32

    def self.parse(tokens : Array(Token), *, allow_invalid : Bool = false) : SyntaxTree
      new(tokens, allow_invalid).parse
    end

    private def initialize(@tokens : Array(Token), @allow_invalid : Bool)
      @pos = 0
      @errors = [] of Error
    end

    def parse : SyntaxTree
      nodes = [] of Node

      loop do
        break unless node = parse_next_node
        nodes << node
        break if @tokens.empty?
      end

      SyntaxTree.new nodes, @errors
    end

    private def parse_next_node : Node?
      case current_token.kind
      in .eof?
        nil
      in .space?
        advance { Space.new current_token }
      in .newline?
        advance { Newline.new current_token }
      in .string?
        parse_scalar_or_mapping current_token
      in .colon?
        parse_mapping next_token
      in .pipe?, .pipe_keep?, .pipe_strip?
        parse_pipe_scalar current_token
      in .fold?, .fold_keep?, .fold_strip?
        parse_folding_scalar current_token
      in .list?
        parse_list current_token
      in .document_start?
        advance { DocumentStart.new current_token.loc }
      in .document_end?
        advance { DocumentEnd.new current_token.loc }
      in .comment?
        parse_comment current_token
      in .directive?
        parse_directive current_token
      end
    end

    private def current_token : Token
      @tokens[@pos]
    end

    private def next_token : Token
      @tokens[@pos += 1]
    end

    private def advance(& : -> T) : T forall T
      value = yield
      next_token
      value
    end

    # TODO: remove this
    private def next_token? : Token?
      @tokens[@pos += 1]?
    end

    private def peek_token : Token
      @tokens[@pos + 1]
    end

    # TODO: replace these with something better
    private def expect_next?(kind : Token::Kind, *, allow_space : Bool = false) : Token?
      expect_next(kind, allow_space: allow_space) rescue nil
    end

    private def expect_next(kind : Token::Kind, *, allow_space : Bool = false) : Token
      case (token = next_token).kind
      when .eof?
        ::raise Error.new "Expected token #{kind}; got End of File", token.loc
      when .comment?
        expect_next kind, allow_space: allow_space
      else
        return token if token.kind == kind

        if token.kind.space? && allow_space
          return expect_next kind, allow_space: allow_space
        end

        raise "Expected token #{kind}; got #{token.kind}", token.loc

        Token.new :space, token.loc, " " # dummy
      end
    end

    private def raise(message : String, loc : Location) : Nil
      ::raise Error.new(message, loc) unless @allow_invalid
      @errors << Error.new(message, loc)
    end

    private def parse_scalar_or_mapping(token : Token) : Node
      if peek_token.kind.colon?
        next_token
        case peek_token.kind
        when .space?, .newline?, .eof?
          return parse_mapping token
        else
          @pos -= 1
        end
      end

      last = uninitialized Token
      value = String.build do |io|
        io << token.value
        last_is_space = token.value.ends_with? ' '

        last = loop do
          case (inner = next_token).kind
          when .string?
            io << inner.value
            last_is_space = inner.value.ends_with? ' '
          when .colon?
            io << ':'
          when .list?
            io << '-'
          when .comment?
            break inner if last_is_space
            io << '#' << inner.value
          when .newline?, .eof?
            break inner
          end
        end
      end

      Scalar.new(token.loc & last.loc, value)
    end

    private def parse_mapping(token : Token) : Node
      key = Scalar.new token.loc, token.value

      # TODO: consider adding a #padding field to account for space/comment after colon
      value = loop do
        case (inner = next_token).kind
        when .space?
          next
        when .newline?
          if peek_token.kind.space?
            next
          else
            break Null.new inner.loc
          end
        when .comment?
          key.comments << Comment.new inner.loc, inner.value
        else
          break parse_next_node || Null.new token.loc
        end
      end

      Mapping.new(token.loc & value.loc, key, value)
    end

    private def parse_pipe_scalar(token : Token) : Node
      expect_next :newline, allow_space: true
      space = expect_next :space
      indent = space.value.size
      last = uninitialized Token
      comments = [] of Comment

      value = String.build do |io|
        last = loop do
          case (inner = next_token).kind
          when .string?, .newline?
            io << inner.value
          when .space?
            break inner if inner.value.size < indent
          when .comment?
            comments << Comment.new token.loc, token.value
          else
            break inner
          end
        end
      end

      value = value.rstrip('\n') unless token.kind.pipe_keep?
      value += "\n" if token.kind.pipe?

      Scalar.new(token.loc & last.loc, value, comments)
    end

    private def parse_folding_scalar(token : Token) : Node
      expect_next :newline, allow_space: true
      space = expect_next :space
      indent = space.value.size
      last = uninitialized Token
      comments = [] of Comment

      value = String.build do |io|
        last = loop do
          case (inner = next_token).kind
          when .string?
            io << inner.value
          when .comment?
            comments << Comment.new inner.loc, inner.value
          when .space?
            break inner if inner.value.size < indent
          when .newline?
            if inner.value.size > 1
              if token.kind.fold_keep?
                io << inner.value
              else
                io << inner.value.byte_slice 1
              end
            else
              io << ' '
            end
          else
            break inner
          end
        end
      end

      value = value.rstrip unless token.kind.fold_keep?
      value += "\n" if token.kind.fold?

      Scalar.new(token.loc & last.loc, value, comments)
    end

    private def parse_list(token : Token) : Node
      start = token.loc
      values = [] of Node
      comments = [] of Comment

      last = loop do
        case token.kind
        when .list?
          next_token
          loop do
            if node = parse_next_node
              values << node
              token = current_token
              break if token.kind.newline?
            else
              values << Null.new token.loc
              break
            end
          end
        when .comment?
          comments << Comment.new token.loc, token.value
          token = next_token
        when .space?, .newline?
          token = next_token
          next
        else
          @pos -= 1 unless token.kind.eof?
          break token
        end
      end

      List.new(start & last.loc, values, comments)
    end

    private def parse_comment(token : Token) : Node
      last = uninitialized Token
      value = String.build do |io|
        io << token.value

        loop do
          unless inner = next_token?
            last = token
            break
          end

          case inner.kind
          when .comment?
            io << '\n' << inner.value
          when .space?, .newline?
            next
          else
            last = inner
            break
          end
        end
      end

      Comment.new(token.loc & last.loc, value)
    end

    private def parse_directive(token : Token) : Node
      expect_next :newline, allow_space: true
      expect_next :document_start, allow_space: true

      case token.value
      when .starts_with? "YAML "
        version = token.value.split(' ', 2).last.strip
        raise "invalid YAML version directive", token.loc unless version.in?("1.0", "1.1", "1.2")
      when .starts_with? "TAG "
        raise "TAG directives are not allowed", token.loc
      end

      Directive.new token.loc, token.value
    end
  end
end
