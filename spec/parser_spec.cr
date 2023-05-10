require "./spec_helper"

describe StrictYAML::Parser do
  describe StrictYAML::Scalar do
    it "parses raw strings" do
      tokens = StrictYAML::Lexer.new("foo bar baz").run
      nodes = StrictYAML::Parser.new(tokens).parse

      nodes.size.should eq 1
      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "foo bar baz"
    end

    it "parses multi-line strings" do
      tokens = StrictYAML::Lexer.new(<<-YAML).run
        foo
        
        bar
        
        baz
        YAML

      nodes = StrictYAML::Parser.new(tokens).parse

      nodes.size.should eq 3
      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "foo"
      nodes[1].as(StrictYAML::Scalar).value.should eq "bar"
      nodes[2].as(StrictYAML::Scalar).value.should eq "baz"
    end

    it "parses pipe scalars" do
      tokens = StrictYAML::Lexer.new(<<-YAML).run
        |
          a scaling pipe string
          wrapped with newlines
        YAML

      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a scaling pipe string\nwrapped with newlines\n"
    end

    it "parses pipe keep scalars" do
      tokens = StrictYAML::Lexer.new(<<-YAML).run
        |+
          a scaling pipe string
          wrapped with newlines


        YAML

      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a scaling pipe string\nwrapped with newlines\n\n"
    end

    it "parses pipe strip scalars" do
      tokens = StrictYAML::Lexer.new(<<-YAML).run
        |-
          a scaling pipe string
          wrapped with newlines
        YAML

      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a scaling pipe string\nwrapped with newlines"
    end

    it "parses folding scalars" do
      tokens = StrictYAML::Lexer.new(<<-YAML).run
        >
          a folding string
          wrapped with spaces
        YAML

      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a folding string wrapped with spaces\n"
    end

    it "parses folding keep scalars" do
      tokens = StrictYAML::Lexer.new(<<-YAML).run
        >+
          a folding string
          wrapped with spaces


        YAML

      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a folding string wrapped with spaces\n\n"
    end

    it "parses folding strip scalars" do
      tokens = StrictYAML::Lexer.new(<<-YAML).run
        >-
          a folding string
          wrapped with spaces
        YAML

      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "a folding string wrapped with spaces"
    end

    it "returns the crystal type object" do
      tokens = StrictYAML::Lexer.new("foo bar baz").run
      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].object.should be_a String
      nodes[0].object.should eq "foo bar baz"
    end
  end

  describe StrictYAML::List do
    it "parses raw lists" do
      tokens = StrictYAML::Lexer.new(<<-YAML).run
        - foo
        - bar
        YAML

      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].should be_a StrictYAML::List
      nodes[0].as(StrictYAML::List).values.size.should eq 2
      nodes[0].as(StrictYAML::List).values[0].should be_a StrictYAML::Scalar
    end

    it "parses nested lists" do
      tokens = StrictYAML::Lexer.new(<<-YAML).run
        - foo
        - - bar
          - - baz
        YAML

      nodes = StrictYAML::Parser.new(tokens).parse

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

    it "returns the crystal type object" do
      tokens = StrictYAML::Lexer.new(<<-YAML).run
        - foo
        - bar
        YAML

      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].object.should be_a Array(StrictYAML::Any)
    end
  end

  describe StrictYAML::Mapping do
    it "parses mappings" do
      tokens = StrictYAML::Lexer.new("foo: bar").run
      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].should be_a StrictYAML::Mapping
      nodes[0].as(StrictYAML::Mapping).key.should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Mapping).value.should be_a StrictYAML::Scalar
    end

    it "parses nested mappings" do
      tokens = StrictYAML::Lexer.new(<<-YAML).run
        foo:
          bar:
            baz:
        YAML

      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].should be_a StrictYAML::Mapping
      nodes[0].as(StrictYAML::Mapping).key.should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Mapping).value.should be_a StrictYAML::Mapping

      nodes[0]
        .as(StrictYAML::Mapping).value
        .as(StrictYAML::Mapping).value.should be_a StrictYAML::Mapping

      nodes[0]
        .as(StrictYAML::Mapping).value
        .as(StrictYAML::Mapping).value
        .as(StrictYAML::Mapping).value.should be_a StrictYAML::Null
    end

    it "returns the crystal type object" do
      tokens = StrictYAML::Lexer.new("foo: bar").run
      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].object.should be_a Hash(StrictYAML::Any, StrictYAML::Any)
    end
  end

  describe StrictYAML::Null do
    it "parses null value" do
      tokens = StrictYAML::Lexer.new("null").run
      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].should be_a StrictYAML::Null
    end

    it "returns the crystal type object" do
      tokens = StrictYAML::Lexer.new("null").run
      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].object.should be_nil
    end
  end

  describe StrictYAML::Boolean do
    it "parses true values" do
      tokens = StrictYAML::Lexer.new("true").run
      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].should be_a StrictYAML::Boolean
      nodes[0].as(StrictYAML::Boolean).value.should be_true

      tokens = StrictYAML::Lexer.new("tRUE").run
      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].should be_a StrictYAML::Boolean
      nodes[0].as(StrictYAML::Boolean).value.should be_true
    end

    it "parses false values" do
      tokens = StrictYAML::Lexer.new("false").run
      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].should be_a StrictYAML::Boolean
      nodes[0].as(StrictYAML::Boolean).value.should be_false

      tokens = StrictYAML::Lexer.new("FaLsE").run
      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].should be_a StrictYAML::Boolean
      nodes[0].as(StrictYAML::Boolean).value.should be_false
    end

    it "returns the crystal type object" do
      tokens = StrictYAML::Lexer.new("true").run
      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].object.should be_a Bool
      nodes[0].object.should be_true
    end

    it "returns the crystal type object" do
      tokens = StrictYAML::Lexer.new("false").run
      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].object.should be_a Bool
      nodes[0].object.should be_false
    end
  end

  describe StrictYAML::Directive do
    tokens = StrictYAML::Lexer.new(<<-YAML).run
      %YAML 1.2
      ---
      foo: bar
      ...
      YAML

    nodes = StrictYAML::Parser.new(tokens).parse

    nodes[0].should be_a StrictYAML::Directive
    nodes[1].should be_a StrictYAML::DocumentStart
    nodes[2].should be_a StrictYAML::Mapping
    nodes[3].should be_a StrictYAML::DocumentEnd
  end
end
