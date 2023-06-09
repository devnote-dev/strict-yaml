require "./spec_helper"

describe StrictYAML do
  it "parses into a document" do
    doc = StrictYAML.parse_document <<-YAML
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
    docs = StrictYAML.parse_documents <<-YAML
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

    docs[0].nodes.size.should eq 2
    docs[0].nodes[0].should be_a StrictYAML::Mapping
    docs[0].nodes[1].should be_a StrictYAML::Mapping

    docs[1].nodes.size.should eq 1
    docs[1].nodes[0].should be_a StrictYAML::List
    docs[1].nodes[0].as(StrictYAML::List).values.size.should eq 2
  end
end
