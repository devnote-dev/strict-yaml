module StrictYAML
  class Editor
    alias KeyType = String | Symbol | Int32
    alias ValueType = KeyType | Nil | Array(ValueType) | Hash(KeyType, ValueType)

    getter document : Document

    def initialize(@document : Document)
      raise "cannot edit an unpreserved document" unless document.preserved?
    end

    def insert(key : KeyType, value : ValueType) : Nil
      insert [key], value
    end

    def insert(keys : Enumerable(KeyType), value : ValueType) : Nil
      if keys.size == 1
        root = lookup keys, insert: true
      else
        root = lookup keys[...-1], insert: true
      end

      case root
      when Mapping
        key = parse keys[-1]

        if root.values.select(Mapping).find { |m| m.key == key }
          raise "key '#{keys.join '.'}' already exists"
        end

        if keys.size == 1
          root.values << Newline.new("\n") << Mapping.new(key, [parse value] of Node)
        else
          raise "invalid mapping sequence" unless root.values[0].is_a?(Newline)

          space = root.values[1].as?(Space) || raise "invalid mapping indentation"
          root.values << Newline.new("\n") << space
          root.values << Mapping.new(key, [Space.new(" "), parse value])
        end
      when List
        root.values << (parse value) << Newline.new("\n")
      end
    end

    def update(key : KeyType, value : ValueType) : Nil
      update [key], value
    end

    def update(keys : Enumerable(KeyType), value : ValueType) : Nil
      if keys.size == 1
        root = lookup keys
      else
        root = lookup keys[...-1]
      end

      case root
      when Mapping
        key = parse keys[-1]

        unless node = root.values.select(Mapping).find { |m| m.key == key }
          raise "key '#{keys.join '.'}' not found"
        end

        node.values.replace [Space.new(" "), parse value]
      when List
        key = keys[-1]
        raise "cannot index a list value with a string key" unless key.is_a?(Int32)

        unless node = root.values[key]?
          raise "key '#{keys.join '.'}' not found"
        end

        unless node.is_a?(List)
          raise "cannot index a scalar or mapping value with a number"
        end

        node.values.replace [parse value]
      end
    end

    def remove(key : KeyType) : Nil
      remove [key]
    end

    def remove(keys : Enumerable(KeyType)) : Nil
      if keys.size == 1
        root = lookup keys
      else
        root = lookup keys[...-1]
      end

      case root
      when Mapping
        key = parse keys[-1]

        unless node = root.values.select(Mapping).find { |m| m.key == key }
          raise "key '#{keys.join '.'}' not found"
        end

        root.values.delete node
        root.values.pop if root.values[-1].is_a?(Space)
        root.values.pop if root.values[-1].is_a?(Newline)
      when List
        key = keys[-1]
        raise "cannot index a list value with a string key" unless key.is_a?(Int32)

        if keys.size == 1
          document.nodes.delete root
          return
        end

        root = lookup keys[...-2]
        unless root.is_a?(List)
          raise "cannot index a scalar or mapping value with a number"
        end

        unless node = root.values[key]?
          raise "key '#{keys.join '.'}' not found"
        end

        root.values.delete node
      end
    end

    private def lookup(keys : Array(KeyType), root : Array(Node) = document.nodes,
                       insert : Bool = false) : Node
      raise "cannot index a scalar document" if document.core_type.scalar?

      case key = keys[0]
      in String, Symbol
        unless document.core_type.mapping?
          raise "cannot index a list document with a string key"
        end

        key = parse key
        if node = root.select(Mapping).find { |m| m.key == key }
          return node if keys.size <= 1

          keys.shift
          lookup keys, node.values, insert
        else
          raise "key '#{key.value}' does not exist"
        end
      in Int32
        unless document.core_type.list?
          raise "cannot index a mapping with a number"
        end

        if node = root.select(List)[key]?
          if keys.size <= 1
            if insert
              root.insert key, list = List.new [Space.new(" ")] of Node
              return list
            else
              return node
            end
          end

          keys.shift
          lookup keys, node.values, insert
        else
          if insert
            root << Newline.new("\n") << (list = List.new [Space.new(" ")] of Node)
            list
          else
            raise "index '#{key}' out of range"
          end
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
