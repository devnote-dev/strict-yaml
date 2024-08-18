require "./spec_helper"

describe StrictYAML::Parser do
  describe StrictYAML::Scalar do
    it "parses raw strings" do
      nodes = parse_nodes "foo bar baz"

      nodes.size.should eq 1
      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "foo bar baz"
    end

    it "parses multi-line strings" do
      nodes = parse_nodes <<-YAML
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
      nodes = parse_nodes <<-YAML
        |
          a scaling pipe string
          wrapped with newlines
        YAML

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a scaling pipe string\nwrapped with newlines\n"
    end

    it "parses pipe keep scalars" do
      nodes = parse_nodes <<-YAML
        |+
          a scaling pipe string
          wrapped with newlines


        YAML

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a scaling pipe string\nwrapped with newlines\n\n"
    end

    it "parses pipe strip scalars" do
      nodes = parse_nodes <<-YAML
        |-
          a scaling pipe string
          wrapped with newlines
        YAML

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a scaling pipe string\nwrapped with newlines"
    end

    it "parses folding scalars" do
      nodes = parse_nodes <<-YAML
        >
          a folding string
          wrapped with spaces
        YAML

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a folding string wrapped with spaces\n"
    end

    it "parses folding keep scalars" do
      nodes = parse_nodes <<-YAML
        >+
          a folding string
          wrapped with spaces


        YAML

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a folding string wrapped with spaces\n\n"
    end

    it "parses folding strip scalars" do
      nodes = parse_nodes <<-YAML
        >-
          a folding string
          wrapped with spaces
        YAML

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a folding string wrapped with spaces"
    end

    it "parses scalars with special tokens" do
      nodes = parse_nodes "foo:bar#baz%qux"

      nodes.size.should eq 1
      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "foo:bar#baz%qux"
    end

    it "parses the crystal type object" do
      nodes = parse_nodes "foo bar baz"

      nodes[0].to_object.should be_a String
      nodes[0].to_object.should eq "foo bar baz"
    end
  end

  describe StrictYAML::List do
    it "parses raw lists" do
      nodes = parse_nodes <<-YAML
        - foo
        - bar
        YAML

      nodes[0].should be_a StrictYAML::List
      nodes[0].as(StrictYAML::List).values.size.should eq 2
      nodes[0].as(StrictYAML::List).values[0].should be_a StrictYAML::Scalar
    end

    it "parses nested lists" do
      nodes = parse_nodes <<-YAML
        - foo
        - - bar
          - - baz
        YAML

      nodes[0].should be_a StrictYAML::List
      nodes[0].as(StrictYAML::List).values.size.should eq 2
      nodes[0].as(StrictYAML::List).values[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::List).values[1].should be_a StrictYAML::List

      nodes[0]
        .as(StrictYAML::List).values[1]
        .as(StrictYAML::List).values.size.should eq 2

      nodes[0]
        .as(StrictYAML::List).values[1]
        .as(StrictYAML::List).values[0].should be_a StrictYAML::Scalar

      nodes[0]
        .as(StrictYAML::List).values[1]
        .as(StrictYAML::List).values[1].should be_a StrictYAML::List

      nodes[0]
        .as(StrictYAML::List).values[1]
        .as(StrictYAML::List).values[1]
        .as(StrictYAML::List).values.size.should eq 1

      nodes[0]
        .as(StrictYAML::List).values[1]
        .as(StrictYAML::List).values[1]
        .as(StrictYAML::List).values[0].should be_a StrictYAML::Scalar
    end

    it "parses the crystal type object" do
      nodes = parse_nodes <<-YAML
        - foo
        - bar
        YAML

      nodes[0].to_object.should be_a Array(StrictYAML::Any)
    end
  end

  describe StrictYAML::Mapping do
    it "parses mappings" do
      nodes = parse_nodes "foo: bar"
      node = nodes[0].should be_a StrictYAML::Mapping

      node.key.should be_a StrictYAML::Scalar
      node.key.as(StrictYAML::Scalar).value.should eq "foo"

      node.values.size.should eq 1
      node.values[0].should be_a StrictYAML::Scalar
      node.values[0].as(StrictYAML::Scalar).value.should eq "bar"
    end

    it "parses nested newline mappings" do
      nodes = parse_nodes <<-YAML
        foo:
          bar:
            baz:
        YAML

      node = nodes[0].should be_a StrictYAML::Mapping
      node.key.should be_a StrictYAML::Scalar
      node.key.as(StrictYAML::Scalar).value.should eq "foo"
      node.values.size.should eq 1

      node = node.values[0].should be_a StrictYAML::Mapping
      node.key.should be_a StrictYAML::Scalar
      node.key.as(StrictYAML::Scalar).value.should eq "bar"
      node.values.size.should eq 1

      node = node.values[0].should be_a StrictYAML::Mapping
      node.key.should be_a StrictYAML::Scalar
      node.key.as(StrictYAML::Scalar).value.should eq "baz"
      node.values.size.should eq 1
      node.values[0].should be_a StrictYAML::Null
    end

    it "parses nested inline mappings" do
      nodes = parse_nodes "foo: bar: baz:"
      node = nodes[0].should be_a StrictYAML::Mapping

      node.key.should be_a StrictYAML::Scalar
      node.key.as(StrictYAML::Scalar).value.should eq "foo"
      node.values.size.should eq 1

      node = node.values[0].should be_a StrictYAML::Mapping
      node.key.should be_a StrictYAML::Scalar
      node.key.as(StrictYAML::Scalar).value.should eq "bar"
      node.values.size.should eq 1

      node = node.values[0].should be_a StrictYAML::Mapping
      node.key.should be_a StrictYAML::Scalar
      node.key.as(StrictYAML::Scalar).value.should eq "baz"
      node.values.size.should eq 1
      node.values[0].should be_a StrictYAML::Null
    end

    it "parses the crystal type object" do
      nodes = parse_nodes "foo: bar"

      nodes[0].to_object.should be_a Hash(StrictYAML::Any, StrictYAML::Any)
    end
  end

  describe StrictYAML::Null do
    it "parses null value" do
      parse_nodes("null")[0].should be_a StrictYAML::Null
    end

    it "parses the crystal type object" do
      parse_nodes("null")[0].to_object.should be_nil
    end
  end

  describe StrictYAML::Boolean do
    it "parses true values" do
      nodes = parse_nodes "true"
      node = nodes[0].should be_a StrictYAML::Boolean
      node.value.should be_true

      nodes = parse_nodes "tRUE"
      node = nodes[0].should be_a StrictYAML::Boolean
      node.value.should be_true
    end

    it "parses false values" do
      nodes = parse_nodes "false"
      node = nodes[0].should be_a StrictYAML::Boolean
      node.value.should be_false

      nodes = parse_nodes "FaLsE"
      node = nodes[0].should be_a StrictYAML::Boolean
      node.value.should be_false
    end

    it "parses the crystal type object" do
      nodes = parse_nodes "true"

      nodes[0].to_object.should be_a Bool
      nodes[0].to_object.should be_true
    end

    it "parses the crystal type object" do
      nodes = parse_nodes "false"

      nodes[0].to_object.should be_a Bool
      nodes[0].to_object.should be_false
    end
  end

  # TODO: requires refinement
  describe StrictYAML::Directive do
    it "parses directives" do
      nodes = parse_nodes <<-YAML
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
