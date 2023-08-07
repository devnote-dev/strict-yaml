module StrictYAML
  class Builder
    @[Flags]
    enum State
      ListStart
      ListBlock
    end

    @io : IO
    @indent : Int32
    @newline : Bool
    getter state : State
    getter? closed : Bool

    def initialize(@io : IO)
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

    def mapping : Nil
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

      if @state.list_block?
        @io << (" " * @indent) if @indent > 0 && !@state.list_start?
        @io << "- " unless @state.list_start?
      end

      if @state.list_start?
        @state &= ~State::ListStart
        @state |= State::ListBlock
      end
    end
  end
end
