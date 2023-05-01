require "./spec_helper"

describe StrictYAML::Lexer do
  it "reads raw values" do
    tokens = StrictYAML::Lexer.new("foo bar baz").run

    tokens.size.should eq 2
    tokens[0].value.should eq "foo bar baz"
    tokens[0].type.should eq StrictYAML::Token::Type::String
    tokens[1].type.should eq StrictYAML::Token::Type::EOF
  end

  it "reads empty values" do
    tokens = StrictYAML::Lexer.new("").run

    tokens.size.should eq 1
    tokens[0].type.should eq StrictYAML::Token::Type::EOF
  end
end
