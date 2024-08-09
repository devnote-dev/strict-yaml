module StrictYAML
  class Parser
    @allow_invalid : Bool
    @errors : Array(Issue)
    @tokens : Array(Token)
    @pos : Int32

    def self.parse(tokens : Array(Token), *, allow_invalid : Bool = false) : SyntaxTree
      new(tokens, allow_invalid).parse
    end

    private def initialize(@tokens : Array(Token), @allow_invalid : Bool)
      @errors = [] of Issue
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
      case (token = next_token).kind
      in .eof?
        nil
      in .space?
        Space.new token
      in .newline?
        Newline.new token
      in .string?
        parse_scalar_or_mapping token
      in .colon?
        parse_mapping token
      in .pipe?, .pipe_keep?, .pipe_strip?
        parse_pipe_scalar token
      in .fold?, .fold_keep?, .fold_strip?
        parse_folding_scalar token
      in .list?
        parse_list token
      in .document_start?
        DocumentStart.new token.loc
      in .document_end?
        DocumentEnd.new token.loc
      in .comment?
        parse_comment token
      in .directive?
        parse_directive token
      end
    end

    private def next_token : Token
      @tokens[@pos += 1]
    end

    # TODO: remove this
    private def next_token? : Token?
      @tokens[@pos += 1]?
    end

    private def peek_token : Token
      @tokens[@pos + 1]
    end

    # TODO: remove this with &
    private def join(start : Position, stop : Position) : Position
      pos = start.dup
      pos.line_stop = stop.line_stop
      pos.column_stop = stop.column_stop

      pos
    end

    # TODO: replace these with something better
    private def expect_next?(kind : Token::Kind, *, allow_space : Bool = false) : Token?
      expect_next(kind, allow_space: allow_space) rescue nil
    end

    private def expect_next(kind : Token::Kind, *, allow_space : Bool = false) : Token
      case (token = next_token).kind
      when .eof?
        ::raise ParseError.new "Expected token #{type}; got End of File"
      when .comment?
        expect_next kind, allow_space: allow_space
      else
        return token if token.kind == kind

        if token.kind.space? && allow_space
          return expect_next kind, allow_space: allow_space
        end

        raise token, "Expected token #{kind}; got #{token.kind}"

        Token.new :space, token.loc, " " # dummy
      end
    end

    private def raise(token : Token, message : String) : Nil
      ::raise ParseError.new message unless @allow_invalid
      @errors << Issue.new(message, token.pos)
    end

    private def parse_scalar_or_mapping(token : Token) : Node
      if peek_token.kind.colon?
        next_token
        case peek_token.kind
        when .space?, .newline?, .eof?
          return parse_mapping token
        else
          @tokens.unshift @prev.as(Token)
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
            if last_is_space
              break inner
            end
            io << '#' << inner.value
          when .newline?, .eof?
            break inner
          end
        end
      end

      Scalar.parse join(token.pos, last.pos), value
    end

    private def parse_mapping(token : Token) : Node
      key = Scalar.parse token.pos, token.value
      value = parse_next_node || Null.new token.pos

      Mapping.new join(token.pos, value.pos), key, value
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
            comments << Comment.new token.pos, token.value
          else
            break inner
          end
        end
      end

      value = value.rstrip('\n') unless token.kind.pipe_keep?
      value += "\n" if token.kind.pipe?

      Scalar.parse join(token.pos, last.pos), value, comments
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
            comments << Comment.new inner.pos, inner.value
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

      Scalar.parse join(token.pos, last.pos), value, comments
    end

    private def parse_list(token : Token) : Node
      values = [] of Node
      comments = [] of Comment
      @tokens.unshift token

      last = loop do
        break token unless inner = next_token?

        case inner.type
        when .list?
          if node = parse_token next_token
            values << node
          else
            values << Null.new inner.pos
            break inner
          end
        when .comment?
          comments << Comment.new inner.pos, inner.value
        when .space?, .newline?
          next
        else
          @tokens.unshift @prev.as(Token)
          break inner
        end
      end

      List.new join(token.pos, last.pos), values, comments
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

          case inner.type
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

      Comment.new join(token.pos, last.pos), value
    end

    private def parse_directive(token : Token) : Node
      expect_next :newline, allow_space: true
      expect_next :document_start, allow_space: true

      case token.value
      when .starts_with? "YAML "
        version = token.value.split(' ', 2).last.strip
        raise token, "invalid YAML version directive" unless version.in?("1.0", "1.1", "1.2")
      when .starts_with? "TAG "
        raise token, "TAG directives are not allowed"
      end

      Directive.new token.pos, token.value
    end
  end
end
