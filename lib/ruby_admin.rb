require "ruby_admin/version"

# +RubyAdmin+ is a library for interacting, programmatically, with the
# resources that surround a system administrator.
#
# A Unix host is just a resource, a programmable switch is a resource,
# a web service is a resource, and much more can be seen as just some
# kind of resource.  A resource class, i.e. a Ruby class derived from
# +RubyAdmin::Resource+, provides an abstraction of a resource kind.
#
# Resource classes can have one or more providers associated with them.
# Providers are usually just different implementations of the mechanism
# by which a resource is accessed.
module RubyAdmin
  autoload :Resource, 'ruby_admin/resource'
  autoload :Scope,    'ruby_admin/scope'
  autoload :Service,  'ruby_admin/service'
  autoload :System,   'ruby_admin/system'

  private

  def dummy
    # method exists only so that Pry can find this module's source
  end
end
