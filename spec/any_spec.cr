require "./spec_helper"

describe StrictYAML::Any do
  it "parses strings" do
    any = StrictYAML.parse "foo bar baz"

    any.raw.should be_a String
    any.as_s.should eq "foo bar baz"

    expect_raises(TypeCastError) { any.as_bool }
    expect_raises(TypeCastError) { any.as_a }
    expect_raises(TypeCastError) { any.as_h }
  end

  it "parses booleans" do
    any = StrictYAML.parse "true"

    any.raw.should be_a Bool
    any.as_bool.should be_true

    any = StrictYAML.parse "false"

    any.raw.should be_a Bool
    any.as_bool.should be_false

    expect_raises(TypeCastError) { any.as_a }
    expect_raises(TypeCastError) { any.as_h }
  end

  pending "allows converting booleans to scalars" do
    any = StrictYAML.parse "true"
    any.as_s.should eq "true"

    any = StrictYAML.parse "false"
    any.as_s.should eq "false"
  end

  it "parses null" do
    any = StrictYAML.parse "null"

    any.raw.should be_nil

    expect_raises(TypeCastError) { any.as_bool }
    expect_raises(TypeCastError) { any.as_s }
    expect_raises(TypeCastError) { any.as_a }
    expect_raises(TypeCastError) { any.as_h }
  end

  it "parses lists" do
    any = StrictYAML.parse <<-YAML
      - foo
      - bar
      - baz
      YAML

    any.raw.should be_a Array(StrictYAML::Any)
    arr = any.as_a
    arr.size.should eq 3

    arr = arr.map &.as_s
    arr.should be_a Array(String)
    arr.should eq %w[foo bar baz]
  end

  it "parses mappings" do
    any = StrictYAML.parse <<-YAML
      foo: bar
      baz: qux
      YAML

    any.raw.should be_a Hash(StrictYAML::Any, StrictYAML::Any)
    hash = any.as_h
    hash.size.should eq 2

    hash = hash.map { |k, v| {k.as_s, v.as_s} }.to_h
    hash.should be_a Hash(String, String)
    hash.should eq({"foo" => "bar", "baz" => "qux"})
  end
end
