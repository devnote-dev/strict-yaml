require "./spec_helper"

describe StrictYAML::Lexer do
  it "reads raw values" do
    tokens = StrictYAML::Lexer.run "foo bar baz"

    tokens.size.should eq 2
    tokens[0].value.should eq "foo bar baz"
    tokens[0].kind.should eq StrictYAML::Token::Kind::String
    tokens[1].kind.should eq StrictYAML::Token::Kind::EOF
  end

  it "reads empty values" do
    tokens = StrictYAML::Lexer.run ""

    tokens.size.should eq 1
    tokens[0].kind.should eq StrictYAML::Token::Kind::EOF
  end
end
