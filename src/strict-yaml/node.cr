module StrictYAML
  class Location
    @value : StaticArray(Int32, 4)

    def self.[](line : Int32, column : Int32)
      new StaticArray[line, column, 0, 0]
    end

    def initialize(@value : StaticArray(Int32, 4))
    end

    def start : {Int32, Int32}
      {@value[0], @value[1]}
    end

    def end : {Int32, Int32}
      {@value[2], @value[3]}
    end

    def end_at(line : Int32, column : Int32) : self
      @value[2] = line
      @value[3] = column

      self
    end

    def &(other : Location) : Location
      Location[@value[0], @value[1]].end_at(*other.end)
    end
  end

  abstract class Node
    property loc : Location
    getter comments : Array(Comment)

    def initialize(@loc : Location, @comments : Array(Comment) = [] of Comment)
    end

    abstract def to_object : Any::Type
  end

  class Space < Node
    property value : String

    def self.new(token : Token)
      new token.loc, token.value
    end

    def initialize(loc : Location, @value : String, @comments : Array(Comment) = [] of Comment)
      super loc
    end

    def to_object : Any::Type
      nil
    end
  end

  class Newline < Node
    property value : String

    def self.new(token : Token)
      new token.loc, token.value
    end

    def initialize(loc : Location, @value : String, @comments : Array(Comment) = [] of Comment)
      super loc
    end

    def to_object : Any::Type
      nil
    end
  end

  class Scalar < Node
    property value : String

    def self.new(value : String)
      new Location[0, 0], value
    end

    def self.new(token : Token)
      new token.loc, token.value
    end

    def initialize(loc : Location, @value : String, @comments : Array(Comment) = [] of Comment)
      super loc
    end

    # TODO: clarify in spec for upcoming #parse:
    # non-quoted scalar == implicit string (CAN be parsed into boolean/null)
    # quoted scalar == explicit string (CANNOT be parsed into boolean/null)
    def quoted?(str : String) : Bool
      (@value.starts_with?('"') && @value.ends_with?('"')) ||
        (@value.starts_with?('\'') && @value.ends_with?('\''))
    end

    def to_object : Any::Type
      @value
    end
  end

  class Boolean < Node
    property value : Bool # ameba:disable Style/QueryBoolMethods

    def self.new(value : Bool)
      new Location[0, 0], value
    end

    def initialize(loc : Location, @value : Bool, @comments : Array(Comment) = [] of Comment)
      super loc
    end

    def to_object : Any::Type
      @value
    end
  end

  class Null < Node
    def self.empty
      new Location[0, 0]
    end

    def initialize(loc : Location, @comments : Array(Comment) = [] of Comment)
      super loc
    end

    def to_object : Any::Type
      nil
    end
  end

  class Mapping < Node
    property key : Node
    property value : Node

    def self.new(key : Node, value : Node)
      new Location[0, 0], key, value
    end

    def initialize(loc : Location, @key : Node, @value : Node)
      super loc
    end

    def to_object : Any::Type
      {Any.new(@key.to_object) => Any.new(@value.to_object)}
    end
  end

  class List < Node
    property values : Array(Node)

    def self.new(values : Array(Node))
      new Location[0, 0], values
    end

    def initialize(loc : Location, @values : Array(Node), comments : Array(Comment) = [] of Comment)
      super loc, comments
    end

    def to_object : Any::Type
      @values.map { |n| Any.new n.to_object }
    end
  end

  class DocumentStart < Node
    def self.empty
      new Location[0, 0]
    end

    def to_object : Any::Type
      nil
    end
  end

  class DocumentEnd < Node
    def self.empty
      new Location[0, 0]
    end

    def to_object : Any::Type
      nil
    end
  end

  class Comment < Node
    property value : String

    def self.new(value : String)
      new Location[0, 0], value
    end

    def initialize(loc : Location, @value : String)
      super loc
    end

    def to_object : Any::Type
      nil
    end
  end

  class Directive < Node
    property value : String

    def self.new(value : String)
      new Location[0, 0], value
    end

    def initialize(loc : Location, @value : String)
      super loc
    end

    def to_object : Any::Type
      nil
    end
  end
end
