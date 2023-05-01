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

    def initialize(@pos : Position, @value : String)
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
end
