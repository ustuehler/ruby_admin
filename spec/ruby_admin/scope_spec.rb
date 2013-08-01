require 'spec_helper'

describe RubyAdmin::Scope do
  context "self.new" do
    it "can evaluate a block in the new scope" do
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
end
