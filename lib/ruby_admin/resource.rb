
module RubyAdmin
  # +Resource+ is the base class for all resource types in +RubyAdmin+.
  #
  # Resources can be anything from networked hosts and operating system
  # services to web APIs.  If access to a resource can be implemented in
  # multiple ways, provided by different Ruby gems, for example, the
  # +Resource::Providable+ module can be mixed in.
  class Resource
    autoload :Providable, "ruby_admin/resource/providable"
    autoload :Provider,   "ruby_admin/resource/provider"

    #####################################################################
    # Resource class methods
    #

    # Return the current scope for resource names, resource name patterns,
    # and so on.
    def self.scope
      RubyAdmin::Scope.current_scope
    end

    # Initialize new subclasses of +Resource+.
    #
    # Called by the Ruby interpreter whenever a subclass of +Resource+ is
    # created, not just for direct subclasses.  `subclass` is the new class
    # and `self` is the base class, which may or may not be +Resource+.
    def self.inherited(subclass)
      subclass.instance_variable_set('@patterns', {})
    end

    @patterns = {} unless defined? @patterns

    # Create a new named resource instance in the current scope.
    def self.create(name, attributes = {}, &block)
      resource = self.new(name, attributes, &block)
      scope.add_resource(name, resource)
      resource
    end

    # Set up pattern matching for resource names in the current scope.
    #
    # Whenever a resource is requested by name and the name matches the
    # given `pattern`, then the associated code block is evaluated with
    # `self` set to the resource class to generate a resource instance.
    def self.match(pattern, options = {}, &block)
      if priority = options[:priority]
        options = options.clone
        options.delete :priority
      else
        priority = 0
      end

      unless options.empty?
        raise ArgumentError, "invalid option(s): #{options.keys.join ', '}"
      end

      scope.add_pattern(self, pattern, priority, &block)
    end

    # Find a named resource of type `self` (or a subtype) in the current
    # scope.
    def self.find(name)
      scope.find(self, name)
    end

    # Like +Resource.find+ but will raise an error if the named resource
    # was not found.
    def self.[](name)
      find(name) or raise RuntimeError, "#{self} resource not found: #{name}"
    end

    #####################################################################
    # Resource instance methods
    #

    attr_reader :name

    def initialize(name, attributes = {})
      @name = name

      attributes.each do |attribute, value|
        method = "#{attribute}="

        if respond_to? method
          send method, value
        else
          raise ArgumentError, "invalid attribute for #{self.class}: #{attribute}"
        end
      end
    end

  end # Resource class
end # RubyAdmin module
