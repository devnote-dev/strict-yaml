require "./spec_helper"

describe StrictYAML do
  it "parses into a document" do
    doc = StrictYAML.parse <<-YAML
      foo: bar
      baz: qux
      YAML

    doc.should be_a StrictYAML::Document
    doc.nodes.size.should eq 2

    doc.nodes[0].should be_a StrictYAML::Mapping
    doc.nodes[0].as(StrictYAML::Mapping).key.should be_a StrictYAML::Scalar
    doc.nodes[0].as(StrictYAML::Mapping).value.should be_a StrictYAML::Scalar
  end

  it "parses multiple documents" do
    docs = StrictYAML.parse_all <<-YAML
      ---
      foo: bar
      baz: qux
      ...
      ---
      - one
      - two
      ...
      YAML

    docs.should be_a Array(StrictYAML::Document)
    docs.size.should eq 2
  end
end
