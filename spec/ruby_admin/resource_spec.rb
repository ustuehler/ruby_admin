require 'spec_helper'

describe RubyAdmin::Resource do

  around(:each) do |example|
    # Use a new temporary scope for each example run to avoid
    # polluting the environment outside of this example group.
    RubyAdmin::Scope.new { example.run }
  end

  describe "self.scope" do
    it "returns a Scope instance" do
      RubyAdmin::Resource.scope.should be_kind_of(RubyAdmin::Scope)
    end
  end

  describe "self.create" do
    it "creates named instances in the current scope" do
      resource_class = RubyAdmin::Resource
      scope = resource_class.scope
      resource = resource_class.create 'test'
      scope.find(resource_class, 'test').should == resource
    end
  end

  it "has no #provide method" do
    RubyAdmin::Resource.methods.should_not include(:provide)
  end

  context "with RubyAdmin::Resource::Providable included" do
    it "has a #provide method" do
      resource_class = Class.new(RubyAdmin::Resource) do
        include RubyAdmin::Resource::Providable
      end

      resource_class.methods.should include(:provide)
    end
  end

end
