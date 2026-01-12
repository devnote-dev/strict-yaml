require "./spec_helper"

describe StrictYAML::Parser do
  describe StrictYAML::Scalar do
    it "parses raw strings" do
      nodes = parse "foo bar baz"
      nodes.size.should eq 1

      node = nodes[0].should be_a StrictYAML::Scalar
      node.value.should eq "foo bar baz"
    end

    it "parses multi-line strings" do
      nodes = parse <<-YAML
        foo

        bar

        baz
        YAML

      nodes.size.should eq 3
      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "foo"
      nodes[1].as(StrictYAML::Scalar).value.should eq "bar"
      nodes[2].as(StrictYAML::Scalar).value.should eq "baz"
    end

    it "parses pipe scalars" do
      nodes = parse <<-YAML
        |
          a scaling pipe string
          wrapped with newlines
        YAML

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a scaling pipe string\nwrapped with newlines\n"
    end

    it "parses pipe keep scalars" do
      nodes = parse <<-YAML
        |+
          a scaling pipe string
          wrapped with newlines


        YAML

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a scaling pipe string\nwrapped with newlines\n\n"
    end

    it "parses pipe strip scalars" do
      nodes = parse <<-YAML
        |-
          a scaling pipe string
          wrapped with newlines
        YAML

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a scaling pipe string\nwrapped with newlines"
    end

    it "parses folding scalars" do
      nodes = parse <<-YAML
        >
          a folding string
          wrapped with spaces
        YAML

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a folding string wrapped with spaces\n"
    end

    it "parses folding keep scalars" do
      nodes = parse <<-YAML
        >+
          a folding string
          wrapped with spaces


        YAML

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a folding string wrapped with spaces\n\n"
    end

    it "parses folding strip scalars" do
      nodes = parse <<-YAML
        >-
          a folding string
          wrapped with spaces
        YAML

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a folding string wrapped with spaces"
    end

    it "parses scalars with special tokens" do
      nodes = parse "foo:bar#baz%qux"

      nodes.size.should eq 1
      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "foo:bar#baz%qux"
    end

    it "parses the crystal type object" do
      nodes = parse "foo bar baz"

      nodes[0].to_object.should be_a String
      nodes[0].to_object.should eq "foo bar baz"
    end
  end

  describe StrictYAML::List do
    it "parses raw lists" do
      nodes = parse <<-YAML
        - foo
        - bar
        YAML

      nodes.size.should eq 2

      node = nodes[0].should be_a StrictYAML::List
      node.values.size.should eq 1
      scalar = node.values[0].should be_a StrictYAML::Scalar
      scalar.value.should eq "foo"

      node = nodes[1].should be_a StrictYAML::List
      node.values.size.should eq 1
      scalar = node.values[0].should be_a StrictYAML::Scalar
      scalar.value.should eq "bar"
    end

    it "parses nested lists" do
      nodes = parse <<-YAML
        - foo
        - - bar
          - - baz
        YAML

      nodes.size.should eq 2

      node = nodes[0].should be_a StrictYAML::List
      node.values.size.should eq 1
      scalar = node.values[0].should be_a StrictYAML::Scalar
      scalar.value.should eq "foo"

      node = nodes[1].should be_a StrictYAML::List
      node.values.size.should eq 1

      list = node.values[0].should be_a StrictYAML::List
      list.values.size.should eq 2
      scalar = list.values[0].should be_a StrictYAML::Scalar
      scalar.value.should eq "bar"

      list = list.values[1].should be_a StrictYAML::List
      list.values.size.should eq 1
      scalar = list.values[0].should be_a StrictYAML::Scalar
      scalar.value.should eq "baz"
    end

    it "parses the crystal type object" do
      nodes = parse <<-YAML
        - foo
        - bar
        YAML

      item = nodes[0].to_object.should be_a Array(StrictYAML::Any)
      item.size.should eq 1
      item[0].should eq "foo"

      item = nodes[1].to_object.should be_a Array(StrictYAML::Any)
      item.size.should eq 1
      item[0].should eq "bar"
    end
  end

  describe StrictYAML::Mapping do
    it "parses mappings" do
      nodes = parse "foo: bar"
      node = nodes[0].should be_a StrictYAML::Mapping

      key = node.key.should be_a StrictYAML::Scalar
      key.value.should eq "foo"

      node.values.size.should eq 1
      scalar = node.values[0].should be_a StrictYAML::Scalar
      scalar.value.should eq "bar"
    end

    it "parses nested newline mappings" do
      nodes = parse <<-YAML
        foo:
          bar:
            baz:
        YAML

      node = nodes[0].should be_a StrictYAML::Mapping
      key = node.key.should be_a StrictYAML::Scalar
      key.value.should eq "foo"
      node.values.size.should eq 1

      node = node.values[0].should be_a StrictYAML::Mapping
      key = node.key.should be_a StrictYAML::Scalar
      key.value.should eq "bar"
      node.values.size.should eq 1

      node = node.values[0].should be_a StrictYAML::Mapping
      key = node.key.should be_a StrictYAML::Scalar
      key.value.should eq "baz"
      node.values.size.should eq 1
      node.values[0].should be_a StrictYAML::Null
    end

    it "parses nested inline mappings" do
      nodes = parse "foo: bar: baz:"
      node = nodes[0].should be_a StrictYAML::Mapping

      key = node.key.should be_a StrictYAML::Scalar
      key.value.should eq "foo"
      node.values.size.should eq 1

      node = node.values[0].should be_a StrictYAML::Mapping
      key = node.key.should be_a StrictYAML::Scalar
      key.value.should eq "bar"
      node.values.size.should eq 1

      node = node.values[0].should be_a StrictYAML::Mapping
      key = node.key.should be_a StrictYAML::Scalar
      key.value.should eq "baz"
      node.values.size.should eq 1
      node.values[0].should be_a StrictYAML::Null
    end

    it "parses the crystal type object" do
      nodes = parse "foo: bar"

      hash = nodes[0].to_object.should be_a Hash(StrictYAML::Any, StrictYAML::Any)
      hash.keys.size.should eq 1
      hash.keys[0].should eq "foo"

      hash.values.size.should eq 1
      hash.values[0].should eq "bar"
    end

    it "parses list-like scalars for mapping values" do
      nodes = parse "foo: -"
      hash = nodes[0].to_object.should be_a Hash(StrictYAML::Any, StrictYAML::Any)
      hash.keys.size.should eq 1
      hash.keys[0].should eq "foo"

      hash.values.size.should eq 1
      hash.values[0].should eq "-"
    end
  end

  describe StrictYAML::Null do
    it "parses null value" do
      parse("null")[0].should be_a StrictYAML::Null
    end

    it "parses the crystal type object" do
      parse("null")[0].to_object.should be_nil
    end
  end

  describe StrictYAML::Boolean do
    it "parses true values" do
      nodes = parse "true"
      node = nodes[0].should be_a StrictYAML::Boolean
      node.value.should be_true

      nodes = parse "tRUE"
      node = nodes[0].should be_a StrictYAML::Boolean
      node.value.should be_true

      nodes = parse "True", sensitive: true
      node = nodes[0].should be_a StrictYAML::Scalar
      node.value.should eq "True"
    end

    it "parses false values" do
      nodes = parse "false"
      node = nodes[0].should be_a StrictYAML::Boolean
      node.value.should be_false

      nodes = parse "FaLsE"
      node = nodes[0].should be_a StrictYAML::Boolean
      node.value.should be_false

      nodes = parse "False", sensitive: true
      node = nodes[0].should be_a StrictYAML::Scalar
      node.value.should eq "False"
    end

    it "parses the crystal type object" do
      parse("true")[0].to_object.should be_true
      parse("false")[0].to_object.should be_false
    end
  end

  # TODO: requires refinement
  describe StrictYAML::Directive do
    it "parses directives" do
      nodes = parse <<-YAML
        %YAML 1.2
        ---
        foo: bar
        ...
        YAML

      nodes.size.should eq 4
      nodes[0].should be_a StrictYAML::Directive
      nodes[1].should be_a StrictYAML::DocumentStart
      nodes[2].should be_a StrictYAML::Mapping
      nodes[3].should be_a StrictYAML::DocumentEnd
    end
  end

  # TODO:
  # describe StrictYAML::Comment do
end
