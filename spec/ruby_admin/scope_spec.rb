require 'spec_helper'

describe RubyAdmin::Scope do
  context "self.new" do
    it "should evaluate a block with new scope on the stack" do
      original_stack = RubyAdmin::Scope.scope_stack

      block_evaluated = false
      RubyAdmin::Scope.new do |scope|
        block_evaluated = true

        RubyAdmin::Scope.current_scope.should == scope
        RubyAdmin::Scope.scope_stack[0...-1].should == original_stack
      end
      block_evaluated.should == true

      RubyAdmin::Scope.scope_stack.should == original_stack
    end
  end

  context "with parent scope" do
    subject do
      RubyAdmin::Scope.new :parent => RubyAdmin::Scope.current_scope
    end

    it "should reach the global scope" do
      subject.parent.should be_kind_of(RubyAdmin::Scope)
      subject.parent.parent.should == RubyAdmin::Scope.global_scope
    end

    it "should shadow parent resources in nested scopes" do
      resource_1 = RubyAdmin::Resource.new('test')
      resource_2 = RubyAdmin::Resource.new('test')
      subject.parent.add_resource 'test', resource_1
      subject.find(RubyAdmin::Resource, 'test').should == resource_1
      subject.add_resource 'test', resource_2
      subject.find(RubyAdmin::Resource, 'test').should == resource_2
    end
  end
end
