require 'spec_helper'

describe RubyAdmin::Resource do

  describe "self.scope" do
    it "returns a Scope instance" do
      RubyAdmin::Resource.scope.should be_kind_of(RubyAdmin::Scope)
    end
  end

  describe "self.create" do
    it "creates named instances in the current scope" do
      scope = RubyAdmin::Resource.scope
      resource = RubyAdmin::Resource.create 'test'
      scope.find(RubyAdmin::Resource, 'test').should == resource
    end
  end

  describe "self.find" do
    it "finds named instances in the current scope" do
      resource = RubyAdmin::Resource.create 'test'
      RubyAdmin::Resource.find('test').should == resource
    end
  end

  describe "self.each" do
    it "iterates over all named resources in the current scope" do
      names = ['test1', 'test2']
      created = []
      yielded = []

      names.each { |name| created << RubyAdmin::Resource.create(name) }
      RubyAdmin::Resource.each { |resource| yielded << resource }
      yielded.should =~ created
    end
  end

  # Primitive resources don't need multiple providers.
  it "has no self.provide method" do
    RubyAdmin::Resource.public_methods.should_not include(:provide)
  end

  context "with ambiguously named resources" do
    subject(:class_1) do
      Class.new(RubyAdmin::Resource)
    end

    subject(:class_2) do
      Class.new(RubyAdmin::Resource)
    end

    it "should allow ambiguous resources of a different class" do
      class_1.create('test').should be_kind_of(class_1)
      class_2.create('test').should be_kind_of(class_2)
    end

    it "should reject ambiguous resources of the same class" do
      class_1.create('test').should be_kind_of(class_1)
      expect { class_1.create('test') }.to raise_error
    end

  end

end
