require 'spec_helper'

describe "RubyAdmin::Resource (providable)" do

  subject(:resource_class) do
    Class.new(RubyAdmin::Resource) do
      include RubyAdmin::Resource::Providable
    end
  end

  it "has a self.provide method" do
    resource_class.public_methods.should include(:provide)
  end

end
