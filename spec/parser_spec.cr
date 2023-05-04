require "./spec_helper"

describe StrictYAML::Parser do
  describe "raw values" do
    it "parses raw strings" do
      tokens = StrictYAML::Lexer.new("foo bar baz").run
      nodes = StrictYAML::Parser.new(tokens).parse

      nodes.size.should eq 1
      nodes[0].should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Scalar).value.should eq "foo bar baz"
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

    it "parses mappings" do
      tokens = StrictYAML::Lexer.new("foo: bar").run
      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].should be_a StrictYAML::Mapping
      nodes[0].as(StrictYAML::Mapping).key.should be_a StrictYAML::Scalar
      nodes[0].as(StrictYAML::Mapping).value.should be_a StrictYAML::Scalar
    end

    it "parses null value" do
      tokens = StrictYAML::Lexer.new("null").run
      nodes = StrictYAML::Parser.new(tokens).parse

      nodes[0].should be_a StrictYAML::Null
    end

    describe "booleans" do
      it "parses truthy values" do
        tokens = StrictYAML::Lexer.new("true").run
        nodes = StrictYAML::Parser.new(tokens).parse

        nodes[0].should be_a StrictYAML::Boolean
        nodes[0].as(StrictYAML::Boolean).value.should be_true

        tokens = StrictYAML::Lexer.new("on").run
        nodes = StrictYAML::Parser.new(tokens).parse

        nodes[0].should be_a StrictYAML::Boolean
        nodes[0].as(StrictYAML::Boolean).value.should be_true

        tokens = StrictYAML::Lexer.new("yes").run
        nodes = StrictYAML::Parser.new(tokens).parse

        nodes[0].should be_a StrictYAML::Boolean
        nodes[0].as(StrictYAML::Boolean).value.should be_true
      end

      it "parses truthy values" do
        tokens = StrictYAML::Lexer.new("false").run
        nodes = StrictYAML::Parser.new(tokens).parse

        nodes[0].should be_a StrictYAML::Boolean
        nodes[0].as(StrictYAML::Boolean).value.should be_false

        tokens = StrictYAML::Lexer.new("no").run
        nodes = StrictYAML::Parser.new(tokens).parse

        nodes[0].should be_a StrictYAML::Boolean
        nodes[0].as(StrictYAML::Boolean).value.should be_false

        tokens = StrictYAML::Lexer.new("off").run
        nodes = StrictYAML::Parser.new(tokens).parse

        nodes[0].should be_a StrictYAML::Boolean
        nodes[0].as(StrictYAML::Boolean).value.should be_false
      end
    end
  end

  describe "nested" do
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
  end

  it "parses directives" do
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
