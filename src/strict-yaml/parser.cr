module StrictYAML
  class Parser
    property? allow_invalid : Bool
    @issues : Array(Issue)
    @tokens : Array(Token)
    @prev : Token?

    def initialize(@tokens : Array(Token), *, @allow_invalid : Bool = false)
      @issues = [] of Issue
    end

    def parse_documents : Array(Document)
      docs = [] of Document
      nodes = [] of Node

      parse.each do |node|
        if node.is_a? DocumentStart
          nodes.clear
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

      docs.each do |document|
        root = find_root document.nodes.reject!(Comment)
        unless document.nodes.all? { |n| n.class == root.class }
          ::raise ParseError.new "mismatched root document types"
        end

        if root.is_a?(Scalar | Boolean | Null)
          document.nodes = parse root, document.nodes
        end
      end

      unless @issues.empty?
        ::raise ParseError.new "YAML documents contained invalid syntax", @issues
      end

      docs
    end

    private def find_root(nodes : Array(Node)) : Node
      nodes.each_with_index do |node, index|
        if node.is_a? Directive
          start = nodes[index + 1]?
          ::raise ParseError.new "unexpected single directive" unless start
          ::raise ParseError.new "expected document start after directive" unless start.is_a? DocumentStart
        elsif node.is_a? Comment
          next
        else
          return node
        end
      end

      ::raise ParseError.new "could not find the root type node"
    end

    private def parse(type : Scalar, nodes : Array(Node)) : Array(Node)
      [Scalar.new(join(nodes.first.pos, nodes.last.pos), nodes.map(&.as(Scalar).value).join(' '))] of Node
    end

    private def parse(type : Boolean, nodes : Array(Node)) : Array(Node)
      if nodes.size == 1
        [nodes[0]] of Node
      else
        [Scalar.new(join(nodes.first.pos, nodes.last.pos), nodes.map(&.as(Boolean).value.to_s).join(' '))] of Node
      end
    end

    private def parse(type : Null, nodes : Array(Node)) : Array(Node)
      if nodes.size == 1
        [nodes[0]] of Node
      else
        [Scalar.new(join(nodes.first.pos, nodes.last.pos), ("null " * nodes.size).chomp)] of Node
      end
    end

    def parse : Array(Node)
      nodes = [] of Node

      loop do
        break unless node = next_node
        nodes << node
        break if end?
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
          @tokens.unshift @prev.as(Token)
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
      when .comment?
        parse_comment token
      when .space?, .newline?
        next_node
      when .directive?
        parse_directive token
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

    private def raise(token : Token, message : String) : Nil
      ::raise ParseError.new message unless @allow_invalid
      @issues << Issue.new(message, token.pos)
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
        case token.type
        when .comment?
          next
        when .eof?
          ::raise ParseError.new "expected token #{type}; got End of File"
        else
          if token.type == type
            return token
          elsif token.type.space? && allow_space
            next
          else
            raise token, "expected token #{type}; got #{token.type}"
            # return token

            # TODO: requires more testing
            dummy = Token.new 0, 0
            dummy.pos = token.pos
            dummy.value = " "

            return dummy
          end
        end
      end
    end

    private def parse_pipe_scalar(token : Token) : Node
      expect_next :newline, allow_space: true
      space = expect_next :space
      indent = space.value.size
      last = uninitialized Token
      comments = [] of Comment

      value = String.build do |io|
        last = loop do
          inner = next_token
          case inner.type
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

      value = value.rstrip('\n') unless token.type.pipe_keep?
      value += "\n" if token.type.pipe?

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
          inner = next_token
          case inner.type
          when .string?
            io << inner.value
          when .comment?
            comments << Comment.new inner.pos, inner.value
          when .space?
            break inner if inner.value.size < indent
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
            break inner
          end
        end
      end

      value = value.rstrip unless token.type.fold_keep?
      value += "\n" if token.type.fold?

      Scalar.parse join(token.pos, last.pos), value, comments
    end

    private def parse_mapping(token : Token) : Node
      key = Scalar.parse token.pos, token.value
      value = next_node || Null.new token.pos

      Mapping.new join(token.pos, value.pos), key, value
    end

    private def parse_list(token : Token) : Node
      values = [] of Node
      comments = [] of Comment
      last = uninitialized Token
      @tokens.unshift token

      loop do
        unless inner = next_token?
          last = token
          break
        end

        case inner.type
        when .comment?
          comments << Comment.new inner.pos, inner.value
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
