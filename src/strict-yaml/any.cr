module StrictYAML
  struct Any
    alias Type = String | Bool | Nil | Array(Any) | Hash(Any, Any)

    getter raw : Type

    def initialize(@raw : Type)
    end

    delegate :==, :===, :to_s, to: @raw

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

    {% for base in %w[8 16 32 64 128] %}
      def to_i{{base.id}} : Int{{base.id}}
        as_s.to_i{{base.id}}
      end

      def to_i{{base.id}}? : Int{{base.id}}?
        as_s.to_i{{base.id}}?
      end

      def to_u{{base.id}} : UInt{{base.id}}
        as_s.to_u{{base.id}}
      end

      def to_u{{base.id}}? : UInt{{base.id}}?
        as_s.to_u{{base.id}}?
      end
    {% end %}

    def to_f32 : Float32
      as_s.to_f32
    end

    def to_f64 : Float64
      as_s.to_f64
    end
  end
end
