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

    abstract def object : Any::Type
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

    def object : Any::Type
      @value
    end
  end

  class Boolean < Node
    property value : Bool

    def initialize(@pos : Position, @value : Bool)
    end

    def object : Any::Type
      @value
    end
  end

  class Null < Node
    def object : Any::Type
      nil
    end
  end

  class Mapping < Node
    property key : Node
    property value : Node

    def initialize(@pos : Position, @key : Node, @value : Node)
    end

    def object : Any::Type
      {Any.new(@key.object) => Any.new(@value.object)}
    end
  end

  class List < Node
    property values : Array(Node)

    def initialize(@pos : Position, @values : Array(Node))
    end

    def object : Any::Type
      @values.map { |n| Any.new n.object }
    end
  end

  class Directive < Node
    property value : String

    def initialize(@pos : Position, @value : String)
    end

    def object : Any::Type
      nil
    end
  end

  class DocumentStart < Node
    def object : Any::Type
      nil
    end
  end

  class DocumentEnd < Node
    def object : Any::Type
      nil
    end
  end
end
