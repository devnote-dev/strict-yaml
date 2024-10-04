require "./spec_helper"

describe StrictYAML::Editor do
  it "inserts mapping values" do
    doc = StrictYAML.parse_document "foo: true", preserve: true
    doc.edit do |editor|
      editor.insert "bar", false
    end

    doc.to_s.should eq "foo: true\nbar: false"
  end

  it "inserts nested mapping values" do
    doc = StrictYAML.parse_document <<-YAML, preserve: true
      foo:
        bar: false
      YAML

    doc.edit do |editor|
      editor.insert %w[foo baz], "true"
    end

    doc.to_s.should eq <<-YAML
      foo:
        bar: false
        baz: true
      YAML
  end

  it "updates mapping values" do
    doc = StrictYAML.parse_document "foo: 123", preserve: true
    doc.edit do |editor|
      editor.update "foo", 456
    end

    doc.to_s.should eq "foo: 456"
  end

  it "updates nested mapping values" do
    doc = StrictYAML.parse_document <<-YAML, preserve: true
      foo:
        bar:
          baz: false
        qux:
          baz: true
      YAML

    doc.edit do |editor|
      editor.update %w[foo bar baz], true
      editor.update %w[foo qux baz], false
    end

    doc.to_s.should eq <<-YAML
      foo:
        bar:
          baz: true
        qux:
          baz: false
      YAML
  end

  it "removes mapping values" do
    doc = StrictYAML.parse_document <<-YAML, preserve: true
      foo: true
      bar: false
      YAML

    doc.edit do |editor|
      editor.remove "bar"
    end

    doc.to_s.should eq "foo: true"
  end

  it "inserts list values" do
    doc = StrictYAML.parse_document "- foo", preserve: true
    doc.edit do |editor|
      editor.insert 1, "bar"
    end

    doc.to_s.should eq "- foo\n- bar"
  end

  pending "inserts nested list values" do
    doc = StrictYAML.parse_document <<-YAML, preserve: true
      - foo
      - - bar
      YAML

    doc.edit do |editor|
      editor.insert [1, 1], "baz"
    end

    doc.to_s.should eq <<-YAML
      - foo
      - - bar
        - baz
      YAML
  end

  it "updates list values" do
    doc = StrictYAML.parse_document <<-YAML, preserve: true
      - foo
      - bar
      YAML

    doc.edit do |editor|
      editor.update [1], "baz"
    end

    doc.to_s.should eq "- foo\n- baz"
  end

  pending "updates nested list values" do
    doc = StrictYAML.parse_document <<-YAML, preserve: true
      - foo
      - - bar
        - qux
      YAML

    doc.edit do |editor|
      editor.update [1, 1], "baz"
    end

    doc.to_s.should eq <<-YAML
      - foo
      - - bar
        - baz
      YAML
  end

  it "removes list values" do
    doc = StrictYAML.parse_document <<-YAML, preserve: true
      - bar
      - foo
      YAML

    doc.edit do |editor|
      editor.remove 0
    end

    doc.to_s.should eq "- foo"
  end

  pending "removes nested list values" do
    doc = StrictYAML.parse_document <<-YAML, preserve: true
      - foo
      - - bar
        - qux
      YAML

    doc.edit do |editor|
      editor.remove [1, 1]
    end

    doc.to_s.should eq <<-YAML
      - foo
      - - bar
      YAML
  end
end
