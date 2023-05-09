module StrictYAML
  class Any
    alias Type = String | Bool | Nil | Array(Type) | Hash(Type, Type)

    getter raw : Type

    def initialize(@raw : Type)
    end

    forward_missing_to @raw

    def as_s : String
      @raw.as(String)
    end

    def as_bool : Bool
      @raw.as(Bool)
    end

    def as_a : Array(Type)
      @raw.as(Array)
    end

    def as_a(type : T.class) : Array(T) forall T
      @raw.as(Array).map &.as(T)
    end

    def as_h : Hash(Type, Type)
      @raw.as(Hash)
    end

    def as_h(_k : K.class, _v : V.class) : Hash(K, V) forall K, V
      @raw.as(Hash).map { |k, v| {k.as(K), v.as(V)} }.to_h
    end
  end
end
