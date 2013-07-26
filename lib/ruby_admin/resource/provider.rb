
# Simple base class for all resource provider classes.
class RubyAdmin::Resource::Provider
  attr_reader :resource

  def initialize(resource)
    @resource = resource
  end
end
