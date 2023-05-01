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
end
