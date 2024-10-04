require "./spec_helper"

describe StrictYAML do
  it "parses into a document" do
    doc = StrictYAML.parse_document <<-YAML
      foo: bar
      baz: qux
      YAML

    doc.should be_a StrictYAML::Document
    doc.nodes.size.should eq 2

    node = doc.nodes[0].should be_a StrictYAML::Mapping
    node.key.should be_a StrictYAML::Scalar
    node.values.size.should eq 1
    node.values[0].should be_a StrictYAML::Scalar
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

    docs[0].nodes.size.should eq 4
    docs[0].nodes[0].should be_a StrictYAML::DocumentStart
    docs[0].nodes[1].should be_a StrictYAML::Mapping
    docs[0].nodes[2].should be_a StrictYAML::Mapping
    docs[0].nodes[3].should be_a StrictYAML::DocumentEnd

    docs[1].nodes.size.should eq 4
    docs[1].nodes[0].should be_a StrictYAML::DocumentStart
    docs[1].nodes[1].should be_a StrictYAML::List
    docs[1].nodes[2].should be_a StrictYAML::List
    docs[1].nodes[3].should be_a StrictYAML::DocumentEnd
  end
end
