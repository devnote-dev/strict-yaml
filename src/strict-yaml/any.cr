module StrictYAML
  struct Any
    alias Type = String | Bool | Nil | Array(Any) | Hash(Any, Any)

    getter raw : Type

    def initialize(@raw : Type)
    end

    forward_missing_to @raw

    def as_s : String
      if @raw.is_a? Bool
        @raw.to_s
      else
        @raw.as(String)
      end
    end

    def as_bool : Bool
      @raw.as(Bool)
    end

    def as_a : Array(Any)
      @raw.as(Array)
    end

    def as_h : Hash(Any, Any)
      @raw.as(Hash)
    end
  end
end
