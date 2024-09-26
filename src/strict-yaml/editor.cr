module StrictYAML
  class Editor
    alias KeyType = String | Symbol | Int32
    alias ValueType = KeyType | Nil | Array(ValueType) | Hash(KeyType, ValueType)

    getter document : Document

    def initialize(@document : Document)
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
        if node = root.values.select(Mapping).find { |m| m.key == key }
          node.values.replace [Space.new(" "), parse value]
        else
          # TODO: needs to check if preserved whitespace
          root.values << Newline.new("\n") << Mapping.new(key, [parse value] of Node)
        end
      when List
        key = keys[-1]
        raise "cannot index a list value with a string key" unless key.is_a?(Int32)

        if node = root.values[key]?
          unless node.is_a?(List)
            raise "cannot index a scalar or mapping value with a number"
          end

          node.values.replace [parse value]
        else
          root.values << parse value
        end
      end
    end

    # def replace(keys : Enumerable(KeyType), value : ValueType) : Nil
    # def remove(keys : Enumerable(KeyType)) : Nil

    private def lookup(keys : Array(KeyType), root : Array(Node) = document.nodes) : Node
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
          lookup keys, node.values
        else
          raise "key '#{key.value}' does not exist"
        end
      in Int32
        unless document.core_type.list?
          raise "cannot index a mapping with a number"
        end

        if node = root.select(List)[key]?
          return node if keys.size <= 1

          keys.shift
          lookup keys, node.values
        else
          raise "index '#{key}' out of range"
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
