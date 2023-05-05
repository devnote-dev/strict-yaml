module StrictYAML
  class Parser
    @tokens : Array(Token)
    @prev : Token?

    def initialize(@tokens : Array(Token))
    end

    def parse_documents : Array(Document)
      docs = [] of Document
      nodes = [] of Node

      parse.each do |node|
        if node.is_a? DocumentStart
          nodes.clear
          nodes << node
        elsif node.is_a? DocumentEnd
          docs << Document.new nodes.dup
          nodes.clear
        else
          nodes << node
        end
      end

      unless nodes.empty?
        docs << Document.new nodes
      end

      # docs.each do |document|
      #   root = document.nodes.first
      #   unless document.nodes.all? &.is_a? root
      #     raise "mismatched root document types"
      #   end
      # end

      docs
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
      parse_token next_token
    end

    private def parse_token(token : Token) : Node?
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
      when .pipe?, .pipe_keep?, .pipe_strip?
        parse_pipe_scalar token
      when .fold?, .fold_keep?, .fold_strip?
        parse_folding_scalar token
      when .list?
        parse_list token
      when .document_start?
        DocumentStart.new token.pos
      when .document_end?
        DocumentEnd.new token.pos
      when .comment?, .space?, .newline?
        next_node
      when .directive?
        Directive.new token.pos, token.value
      when .eof?
        nil
      end
    end

    private def next_token : Token
      @prev = @tokens.shift
    end

    private def next_token? : Token?
      @prev = @tokens.shift?
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

    private def expect_next?(type : Token::Type, *, allow_space : Bool = false) : Token?
      expect_next(type, allow_space: allow_space) rescue nil
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
          else
            io << inner.value
          end
        end
      end

      value = value.rstrip('\n') unless token.type.pipe_keep?
      value += "\n" if token.type.pipe?

      Scalar.parse join(token.pos, last.pos), value
    end

    private def parse_folding_scalar(token : Token) : Node
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
            if inner.value.size > 1
              if token.type.fold_keep?
                io << inner.value
              else
                io << inner.value.byte_slice 1
              end
            else
              io << ' '
            end
          else
            io << inner.value
          end
        end
      end

      value = value.rstrip unless token.type.fold_keep?
      value += "\n" if token.type.fold?

      Scalar.parse join(token.pos, last.pos), value
    end

    private def parse_list(token : Token) : Node
      values = [] of Node
      last = uninitialized Token
      @tokens.unshift token

      loop do
        unless inner = next_token?
          last = token
          break
        end

        case inner.type
        when .space?, .newline?
          next
        when .list?
          if node = parse_token(next_token)
            values << node
          else
            values << Null.new inner.pos
            last = inner
            break
          end
        else
          last = inner
          break
        end
      end

      List.new join(token.pos, last.pos), values
    end

    private def parse_mapping(token : Token) : Node
      key = Scalar.parse token.pos, token.value
      value = next_node || Null.new token.pos

      Mapping.new join(token.pos, value.pos), key, value
    end
  end
end
