require "./spec_helper"

describe StrictYAML::Builder do
  it "emits directives" do
    StrictYAML::Builder.build do |b|
      b.directive "YAML 1.2"
    end.should eq "%YAML 1.2\n"
  end

  it "emits document markers" do
    StrictYAML::Builder.build do |b|
      b.document_start
      b.document_end
    end.should eq "---\n...\n"
  end

  it "emits scalar values" do
    StrictYAML::Builder.build do |b|
      b.scalar nil
      b.scalar "foo"
      b.scalar 123
      b.scalar true
    end.should eq "\nfoo\n123\ntrue\n"
  end

  it "emits boolean and null values" do
    StrictYAML::Builder.build do |b|
      b.boolean true
      b.null
      b.boolean false
    end.should eq "true\nnull\nfalse\n"
  end

  it "emits mappings" do
    StrictYAML::Builder.build do |b|
      b.mapping do |m|
        m.scalar "foo"
        m.boolean true
      end
    end.should eq "foo: true"

    StrictYAML::Builder.build do |b|
      b.mapping do |x|
        x.scalar "foo"
        x.mapping do |y|
          y.scalar "bar"
          y.mapping do |z|
            z.scalar "baz"
            z.scalar "qux"
          end
        end
      end
    end.should eq <<-YAML
      foo:
        bar:
          baz: qux
      YAML
  end

  pending "emits lists" { }
end
