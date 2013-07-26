
# +Resource+ is the base class for all resource types in +RubyAdmin+.
# Resources can be anything from networked hosts and operating system
# services to web APIs.
class RubyAdmin::Resource
  autoload :Provider, "ruby_admin/resource/provider"

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
    subclass.instance_variable_set('@provider_classes', {})
  end

  @patterns = {} unless defined? @patterns
  @provider_classes = {} unless defined? @provider_classes

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

  # Define a named provider class for this +Resource+ class (or subclass).
  def self.provide(name, attributes = {}, &block)
    name = name.to_s

    if parent = attributes[:parent]
      attributes = attributes.clone
      parent_class = provider_class(parent)
      attributes.delete :parent
    else
      parent_class = Provider
    end

    unless attributes.empty?
      raise ArgumentError, "invalid provider attribute(s): #{attributes.keys.join ', '}"
    end

    if provider_class = @provider_classes[name.to_s]
      provider_class.class_eval(&block)
    else
      resource_class = self
      provider_class = Class.new(parent_class) do
        [:inspect, :to_s, :to_str, :name].each do |m|
        define_singleton_method(m) do
          "#<#{resource_class} provider #{name.inspect}>"
        end
        end
      end

      @provider_classes[name.to_s] = provider_class
    end

    provider_class.class_eval(&block)
  end

  # Return the named provider class for this resource class.
  def self.provider_class(name)
    name = name.to_s

    @provider_classes[name] or raise "no such provider for #{self}: #{name}"
  end

  # Return all named provider classes for this resource class.
  def self.provider_classes
    @provider_classes.keys.map { |k| k.to_sym }
  end

  #####################################################################
  # Resource instance methods
  #

  attr_reader :name
  attr_reader :provider

  def provider=(provider)
    @provider = self.class.provider_class(provider).new(self)
  end

  def initialize(name, attributes = {})
    @name = name

    # FIXME: should have a way for provider classes to return whether
    # they can handle the given resource or not, etc.  Just picking
    # the first one is definitely wrong in the long run.
    provider_classes = self.class.provider_classes
    if !provider_classes.empty?
      attributes[:provider] ||= provider_classes.sort.first
    end

    attributes.each do |attribute, value|
      method = "#{attribute}="

      if respond_to? method
        send method, value
      else
        raise ArgumentError, "invalid attribute for #{self.class}: #{attribute}"
      end
    end
  end
end
