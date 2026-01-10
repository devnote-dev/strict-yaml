module StrictYAML
  class Editor
    alias KeyType = String | Symbol | Int32
    alias ValueType = KeyType | Bool | Nil | Array(ValueType) | Hash(KeyType, ValueType)

    @document : Document

    def initialize(@document : Document)
      raise "cannot edit an unpreserved document" unless document.preserved?
    end

    def insert(key : KeyType, value : ValueType) : Nil
      insert [key], value
    end

    def insert(keys : Enumerable(KeyType), value : ValueType) : Nil
      lookup_insert keys, 0, value, @document.nodes, @document.core_type
    end

    def update(key : KeyType, value : ValueType) : Nil
      update [key], value
    end

    def update(keys : Enumerable(KeyType), value : ValueType) : Nil
      lookup_update keys, value, @document.nodes, @document.core_type
    end

    def remove(key : KeyType) : Nil
      remove [key]
    end

    def remove(keys : Enumerable(KeyType)) : Nil
      lookup_remove keys, @document.nodes, @document.core_type
    end

    private def lookup_insert(keys : Enumerable(KeyType), index : Int32, value : ValueType,
                              nodes : Array(Node), type : Document::CoreType) : Nil
      raise "cannot index a scalar document" if type.scalar?

      case key = keys[index]
      in String, Symbol
        raise "cannot index a list item with a string key" unless type.mapping?

        key = parse key
        if node = nodes.select(Mapping).find { |m| m.key == key }
          if keys.size == 1
            raise "key '#{key.value}' already exists in mapping"
          else
            lookup_insert keys, index + 1, value, node.values, :mapping
          end
        else
          if index != keys.size - 1
            raise "key '#{key.value}' not found in mapping"
          end

          unless index == 0
            nodes.clear << Newline.new("\n") << Space.new("  " * index)
          end
          nodes << Mapping.new key, [Space.new(" "), parse value]
        end
      in Int32
        raise "cannot index a mapping item with an integer key" unless type.list?

        if node = nodes.select(List)[key]?
          if keys.size == 1
            nodes.insert key, List.new [Space.new(" "), (parse value), Newline.new("\n")]
          else
            keys.shift
            lookup_insert keys, value, node.values, :list
          end
        else
          nodes << Newline.new("\n") << List.new [Space.new(" "), (parse value)]
        end
      end
    end

    private def lookup_update(keys : Enumerable(KeyType), value : ValueType,
                              nodes : Array(Node), type : Document::CoreType) : Nil
      raise "cannot index a scalar document" if type.scalar?

      case key = keys[0]
      in String, Symbol
        raise "cannot index a list item with a string key" unless type.mapping?

        key = parse key
        if node = nodes.select(Mapping).find { |m| m.key == key }
          if keys.size == 1
            node.values.replace [Space.new(" "), parse value]
          else
            keys.shift
            lookup_update keys, value, node.values, :mapping
          end
        else
          raise "key '#{key.value}' not found in mapping"
        end
      in Int32
        raise "cannot index a mapping item with an integer key" unless type.list?

        if node = nodes.select(List)[key]?
          if keys.size == 1
            node.values.replace [Space.new(" "), parse value]
          else
            keys.shift
            lookup_update keys, value, node.values, :list
          end
        else
          raise "index '#{key}' out of range for list"
        end
      end
    end

    private def lookup_remove(keys : Enumerable(KeyType), nodes : Array(Node), type : Document::CoreType) : Nil
      raise "cannot index a scalar document" if @document.core_type.scalar?

      case key = keys[0]
      in String, Symbol
        raise "cannot index a list item with a string key" unless type.mapping?

        key = parse key
        if node = nodes.select(Mapping).find { |m| m.key == key }
          if keys.size == 1
            nodes.delete node
            nodes.pop if nodes[-1].is_a?(Space)
            nodes.pop if nodes[-1].is_a?(Newline)
          else
            keys.shift
            lookup_remove keys, node.values, :mapping
          end
        else
          raise "key '#{key.value}' not found in mapping"
        end
      in Int32
        raise "cannot index a mapping item with an integer key" unless type.list?

        if node = nodes.select(List)[key]?
          if keys.size == 1
            nodes.delete node
          else
            keys.shift
            lookup_remove keys, node.values, :list
          end
        else
          raise "index '#{key}' out of range for list"
        end
      end
    end

    private def parse(value : String | Symbol | Number) : Node
      Scalar.new value.to_s
    end

    private def parse(value : Bool) : Node
      Boolean.new value
    end

    private def parse(value : Nil) : Node
      Null.empty
    end

    private def parse(value : Array(_)) : Node
      List.new value.map { |i| parse i }
    end
  end
end
