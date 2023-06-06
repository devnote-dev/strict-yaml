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
    property comments : Array(Comment)

    def initialize(@pos : Position, @comments : Array(Comment) = [] of Comment)
    end

    abstract def to_object : Any::Type
  end

  class Scalar < Node
    property value : String

    def self.new(value : String)
      new Position.new(0, 0), value
    end

    def self.parse(value : String)
      parse Position.new(0, 0), value
    end

    def self.parse(pos : Position, value : String, comments : Array(Comment) = [] of Comment)
      if quoted? value
        char = value[0]
        return new pos, value.strip(char), comments
      end

      case value.downcase
      when "true"  then Boolean.new pos, true, comments
      when "false" then Boolean.new pos, false, comments
      when "null"  then Null.new pos
      else              new pos, value.strip(' '), comments
      end
    end

    def self.quoted?(str : String) : Bool
      (str.starts_with?('"') && str.ends_with?('"')) ||
        (str.starts_with?('\'') && str.ends_with?('\''))
    end

    def initialize(pos : Position, @value : String, @comments : Array(Comment) = [] of Comment)
      super pos
    end

    def to_object : Any::Type
      @value
    end
  end

  class Boolean < Node
    property value : Bool # ameba:disable Style/QueryBoolMethods

    def self.new(value : Bool)
      new Position.new(0, 0), value
    end

    def initialize(pos : Position, @value : Bool, @comments : Array(Comment) = [] of Comment)
      super pos
    end

    def to_object : Any::Type
      @value
    end
  end

  class Null < Node
    def self.empty
      new Position.new(0, 0)
    end

    def initialize(pos : Position, @comments : Array(Comment) = [] of Comment)
      super pos
    end

    def to_object : Any::Type
      nil
    end
  end

  class Mapping < Node
    property key : Node
    property value : Node

    def self.new(key : Node, value : Node)
      new Position.new(0, 0), key, value
    end

    def initialize(pos : Position, @key : Node, @value : Node)
      super pos
    end

    def to_object : Any::Type
      {Any.new(@key.to_object) => Any.new(@value.to_object)}
    end
  end

  class List < Node
    property values : Array(Node)

    def self.new(values : Array(Node))
      new Position.new(0, 0), values
    end

    def initialize(pos : Position, @values : Array(Node), comments : Array(Comment) = [] of Comment)
      super pos, comments
    end

    def to_object : Any::Type
      @values.map { |n| Any.new n.to_object }
    end
  end

  class DocumentStart < Node
    def self.empty
      new Position.new(0, 0)
    end

    def to_object : Any::Type
      nil
    end
  end

  class DocumentEnd < Node
    def self.empty
      new Position.new(0, 0)
    end

    def to_object : Any::Type
      nil
    end
  end

  class Comment < Node
    property value : String

    def self.new(value : String)
      new Position.new(0, 0), value
    end

    def initialize(pos : Position, @value : String)
      super pos
    end

    def to_object : Any::Type
      nil
    end
  end

  class Directive < Node
    property value : String

    def self.new(value : String)
      new Position.new(0, 0), value
    end

    def initialize(pos : Position, @value : String)
      super pos
    end

    def to_object : Any::Type
      nil
    end
  end
end
