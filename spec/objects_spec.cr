require "./spec_helper"

private enum Color
  Red
  Green
  Blue
end

# @[Flags]
# private enum Mode
#   Read
#   Write
#   Async
# end

describe StrictYAML do
  it "parses to integers" do
    value = Int32.from_strict_yaml "123456"

    value.should be_a Int32
    value.should eq 123456
  end

  it "parses to floats" do
    value = Float64.from_strict_yaml "3.14159265"

    value.should be_a Float64
    value.should eq 3.14159265_f64
  end

  it "parses to strings" do
    value = String.from_strict_yaml "foo bar baz"

    value.should be_a String
    value.should eq "foo bar baz"
  end

  it "parses to booleans" do
    value = Bool.from_strict_yaml "true"

    value.should be_a Bool
    value.should be_true

    value = Bool.from_strict_yaml "false"

    value.should be_a Bool
    value.should be_false
  end

  it "parses to char" do
    value = Char.from_strict_yaml "0"

    value.should be_a Char
    value.should eq '0'
  end

  it "parses to paths" do
    value = Path.from_strict_yaml "/dev/null"

    value.should be_a Path
    value.should eq Path["/dev/null"]
  end

  it "parses to an array" do
    value = Array(Int32).from_strict_yaml <<-YAML
      - 123
      - 456
      - 789
      YAML

    value.should be_a Array(Int32)
    value.size.should eq 3
    value.should eq [123, 456, 789]
  end

  it "parses to a set" do
    value = Set(Int32).from_strict_yaml <<-YAML
      - 456
      - 123
      - 789
      - 123
      - 456
      YAML

    value.should be_a Set(Int32)
    value.size.should eq 3
    value.should eq Set{456, 123, 789}
  end

  it "parses to a tuple" do
    value = Tuple(String, String).from_strict_yaml <<-YAML
      - foo
      - bar
      YAML

    value.should be_a Tuple(String, String)
    value.should eq({"foo", "bar"})
  end

  it "parses to a hash" do
    value = Hash(String, String).from_strict_yaml <<-YAML
      foo: bar
      baz: qux
      YAML

    value.should be_a Hash(String, String)
    value.should eq({"foo" => "bar", "baz" => "qux"})
  end

  it "parses to a named tuple" do
    value = NamedTuple(foo: String, bar: Int32).from_strict_yaml <<-YAML
      foo: 12
      bar: 34
      YAML

    value.should be_a NamedTuple(foo: String, bar: Int32)
    value.should eq({foo: "12", bar: 34})
  end

  it "parses normal enums" do
    value = Array(Color).from_strict_yaml <<-YAML
        - red
        - blue
        YAML

    value.should be_a Array(Color)
    value.should eq [Color::Red, Color::Blue]
  end

  # FIXME: doesn't work in specs because of macro generation
  # it "parses flag enums" do
  #   value = Mode.from_strict_yaml <<-YAML
  #       - read
  #       - write
  #       YAML

  #   value.should be_a Mode
  #   value.should eq Mode::Read | Mode::Write
  # end
end
