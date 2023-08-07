module StrictYAML
  class Builder
    @[Flags]
    enum State
      ListStart
      ListBlock
      MappingStart
      MappingBlock
    end

    enum Kind
      List
      Map
    end

    @io : IO
    @level : Int32
    @indent : Int32
    @newline : Bool
    getter state : State
    getter? closed : Bool

    def initialize(@io : IO)
      @level = 0
      @indent = -2
      @newline = false
      @state = :none
      @closed = false
    end

    def document(*, version : String? = nil, & : ->) : Nil
      document_start version: version
      yield
      check_state
      document_end
    end

    def document_start(*, version : String? = nil) : Nil
      unless version.nil?
        @io << "%YAML " << version << '\n'
      end
      @io << "---"
      @newline = true
    end

    def document_end : Nil
      @io << "..."
      @newline = true
    end

    def scalar(value : _, *, quote : Bool = false) : Nil
      check_state
      if quote
        @io << '"' << value << '"'
      else
        @io << value
      end
      @newline = true
    end

    def boolean(value : Bool) : Nil
      check_state
      @io << value
      @newline = true
    end

    def null : Nil
      check_state
      @io << "null"
      @newline = true
    end

    def list(& : ->) : Nil
      check_state
      @io << "- "
      @indent += 2
      @state |= State::ListStart

      yield

      @indent -= 2
      @state &= ~State::ListBlock
    end

    def mapping(key : _, value : _) : Nil
      check_state
      @io << quote(key) << ": " << value
      @newline = true
    end

    def mapping(kind : Kind, key : _, & : ->) : Nil
      check_state
      @io << quote(key) << ":\n"
      if kind.list?
        list { yield }
      else
        @io << "  "
        @level += 2
        @state |= State::MappingStart

        yield

        @level -= 2
        @state &= ~State::MappingStart
      end
    end

    def comment(text : String) : Nil
      @io << "  # " << text
      @newline = true
    end

    def close : Nil
      return if @closed

      check_state
      @io.flush
      @closed = true
    end

    private def check_state : Nil
      if @newline
        @io << '\n'
        @newline = false
      end

      if @state.mapping_block?
        @io << (" " * @level) unless @state.mapping_start? || @state.list_start?
      end

      if @state.mapping_start?
        @state &= ~State::MappingStart
        @state |= State::MappingBlock
      end

      if @state.list_block?
        @io << (" " * @indent) if @indent > 0 && !@state.list_start?
        @io << "- " unless @state.list_start?
      end

      if @state.list_start?
        @state &= ~State::ListStart
        @state |= State::ListBlock
      end
    end

    private def quote(value) : String
      case value
      when Number, String, Bool, Char, Path, Symbol
        value
      else
        str = value.to_s
        if str.includes? ' '
          str = "'" + str + "'"
        end
        str
      end
    end
  end
end
