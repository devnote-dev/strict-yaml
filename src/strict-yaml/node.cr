module StrictYAML
  class Position
    property line_start : Int32
    property line_stop : Int32
    property column_start : Int32
    property column_stop : Int32

    def initialize(@line_start : Int32, @column_start : Int32)
      @line_stop = @column_stop = 0
    end
  end

  abstract class Node
    getter pos : Position

    def initialize(@pos : Position)
    end
  end

  class Scalar < Node
    property value : String

    def self.parse(pos : Position, value : String)
      if quoted? value
        char = value[0]
        return new pos, value.strip(char)
      end

      case value.downcase
      when .in?("true", "yes", "on")
        Boolean.new pos, true
      when .in?("false", "no", "off")
        Boolean.new pos, false
      when "null"
        Null.new pos
      else
        new pos, value
      end
    end

    def self.quoted?(str : String) : Bool
      (str.starts_with?('"') && str.ends_with?('"')) ||
        (str.starts_with?('\'') && str.ends_with?('\''))
    end

    def initialize(@pos : Position, @value : String)
    end
  end

  class Boolean < Node
    property value : Bool

    def initialize(@pos : Position, @value : Bool)
    end
  end

  class Mapping < Node
    property key : Scalar | Null
    property value : Node?

    def initialize(@pos : Position, @key : Scalar | Null, @value : Node?)
    end
  end

  class List < Node
    property values : Array(Node)

    def initialize(@pos : Position, @values : Array(Node))
    end
  end

  class Null < Node
  end

  class DocStart < Node
  end

  class DocEnd < Node
  end
end
