
# +Scope+ has an optional parent scope and can store and retrieve other
# resource parameter defaults, resources and such.
class RubyAdmin::Scope
  attr_accessor :parent, :namespace, :source, :resource

  NAMESPACE_SEPARATOR = '::'

  def self.current_scope
    @scope_stack ||= [self.new]
    @scope_stack.last
  end

  # Initialize a new scope.  Unless the :parent attribute is specified,
  # the new scope will have no parent scope and is therefore a top-level
  # scope.
  def initialize(attributes = {})
    @defaults = {}
    @resources = {}
    @named_scopes = {}
    @patterns = {}

    attributes.each do |name, value|
      method = "#{name}="

      if respond_to? method
        send method, value
      else
        raise ArgumentError, "invalid scope argument: #{name}"
      end
    end

    yield self if block_given?
  end

  # Add a named scope.  It is an error if a scope of the same name
  # already exists in this scope.
  def add_scope(name, scope)
    if @named_scope.has_key? name
      raise RuntimeError, "duplicate named scope #{name.inspect} in scope #{self.qualified_name.inspect}"
    end

    @named_scopes[name] = scope
  end

  # Add a named resource to the scope.  It is an error if a resource of
  # the same name already exists in this scope.
  def add_resource(name, resource)
    name = name.to_s

    if @resources.has_key? name
      raise RuntimeError, "duplicate resource name #{name.inspect} in scope #{self.qualified_name.inspect}"
    end

    @resources[name] = resource
  end

  # Add a pattern associated with the given class to match against unknown
  # resource names within this scope.
  def add_pattern(klass, pattern, priority, &block)
    @patterns[klass] ||= {}
    @patterns[klass][priority] ||= []
    @patterns[klass][priority].delete_if { |p, _| p == pattern }
    @patterns[klass][priority] << [pattern, block]
  end

  # Find a named resource of the given type (whose class is `klass` or a
  # subclass) in this scope.
  def find(klass, name)
    name = name.to_s

    if @resources.has_key? name
      if (r = @resources[name]).kind_of? klass
        return r
      else
        raise "resource named #{name.inspect} is a #{r.class}, expected #{klass}"
      end
    end

    return nil unless @patterns.has_key? klass

    @patterns[klass].keys.sort.reverse.each do |priority|
      @patterns[klass][priority].each do |pattern, block|
        next unless m = pattern.match(name)

        resource = klass.send :instance_exec, name, *m.captures, &block

        unless resource.is_a? klass
          raise RuntimeError, "resource returned by block for pattern #{pattern} is not a #{klass}: #{resource.inspect}"
        end

        return resource
      end
    end

    return nil
  end
end
