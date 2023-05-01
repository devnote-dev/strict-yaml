module StrictYAML
  class Parser
    @tokens : Array(Token)
    @prev : Token?

    def initialize(@tokens : Array(Token))
    end

    def parse : Array(Node)
      nodes = [] of Node

      loop do
        if node = next_node
          nodes << node
          break if end?
        else
          break
        end
      end

      nodes
    end

    private def next_node : Node?
      token = next_token

      case token.type
      when .string?
        if next_token.type.colon?
          parse_mapping token
        else
          @tokens.unshift @prev.not_nil!
          Scalar.parse token.pos, token.value
        end
      when .colon?
        parse_mapping token
      when .pipe?
        parse_pipe_scalar token
      when .greater?
        parse_greater_scalar token
      when .space?, .newline?
        next_node
      when .eof?
        nil
      end
    end

    private def next_token : Token
      @prev = @tokens.shift
    end

    private def end? : Bool
      @tokens.empty?
    end

    private def join(start : Position, stop : Position) : Position
      pos = start.dup
      pos.line_stop = stop.line_stop
      pos.column_stop = stop.column_stop

      pos
    end

    private def expect_next(type : Token::Type, *, allow_space : Bool = false) : Token
      loop do
        token = next_token
        next if token.type.comment?
        next if token.type.space? && allow_space
        raise "expected token #{type}; got #{token.type}" unless token.type == type
        return token
      end
    end

    private def parse_pipe_scalar(token : Token) : Node
      expect_next :newline, allow_space: true
      space = expect_next :space
      indent = space.value.size
      last = uninitialized Token

      value = String.build do |io|
        loop do
          inner = next_token
          case inner.type
          when .eof?
            last = inner
            break
          when .space?
            if inner.value.size < indent
              last = inner
              break
            else
              io << inner.value.byte_slice indent
            end
          when .newline?
            io << '\n'
          else
            io << inner.value
          end
        end
      end

      Scalar.parse join(token.pos, last.pos), value
    end

    private def parse_greater_scalar(token : Token) : Node
      expect_next :newline, allow_space: true
      space = expect_next :space
      indent = space.value.size
      last = uninitialized Token

      value = String.build do |io|
        loop do
          inner = next_token
          case inner.type
          when .eof?
            last = inner
            break
          when .space?
            if inner.value.size < indent
              last = inner
              break
            end
          when .newline?
            io << ' '
          else
            io << inner.value
          end
        end
      end

      Scalar.parse join(token.pos, last.pos), value
    end

    private def parse_mapping(token : Token) : Node
      key = Scalar.new token.pos, token.value
      value = next_node || Null.new token.pos

      Mapping.new join(token.pos, value.pos), key, value
    end
  end
end
