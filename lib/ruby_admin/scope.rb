
# +Scope+ can store and retrieve named resources, resource name
# patterns and such.
class RubyAdmin::Scope
  attr_accessor :parent

  # Return the global scope singleton.
  def self.global_scope
    @@global_scope ||= self.new :parent => nil
  end

  # Return the current scope stack.
  def self.scope_stack
    # Always create the global scope implicitly.
    @@scope_stack ||= [global_scope]
    @@scope_stack.clone
  end

  # Return the top of the scope stack.
  def self.current_scope
    scope_stack.last
  end

  # Call the given block with `scope' pushed temporarily onto the
  # scope stack.
  def self.scope_eval(scope, &block)
    new_stack = scope_stack
    original_stack = @@scope_stack
    begin
      new_stack.push scope
      @@scope_stack = new_stack

      block.call
    ensure
      @@scope_stack = original_stack
    end
  end

  # Initialize a new scope.
  def initialize(attributes = {}, &block)
    @resources = {}
    @patterns = {}

    unless attributes.has_key? :parent
      self.parent = self.class.current_scope
    end

    attributes.each do |name, value|
      method = "#{name}="

      if respond_to? method
        send method, value
      else
        raise ArgumentError, "invalid scope argument: #{name}"
      end
    end

    self.class.scope_eval(self) { block.call(self) } if block
  end

  # Add a named scope.  It is an error if a scope of the same name
  # already exists in this scope.
  def add_scope(name, scope)
    if @named_scope.has_key? name
      raise RuntimeError, "duplicate named scope #{name.inspect} in scope #{self.qualified_name.inspect}"
    end

    @named_scopes[name] = scope
  end

  # Return the list of all named resource instances in this scope.
  def resources
    @resources.map { |resource_class, named_resources|
      named_resources.values
    }.flatten
  end

  # Add a named resource to the scope.  It is an error if a resource of
  # the same name already exists in this scope.
  def add_resource(name, resource)
    name = name.to_s

    @resources[resource.class] ||= {}

    if @resources[resource.class].has_key? name
      raise RuntimeError, "duplicate #{resource.class} resource #{name.inspect} in scope #{self}"
    end

    @resources[resource.class][name] = resource
  end

  # Add a pattern associated with the given class to match against unknown
  # resource names within this scope.
  def add_pattern(klass, pattern, priority, &block)
    @patterns[klass] ||= {}
    @patterns[klass][priority] ||= []
    @patterns[klass][priority].delete_if { |p, _| p == pattern }
    @patterns[klass][priority] << [pattern, block]
  end

  # Find a named resource of the given type (whose class is
  # `resource_class` or a subclass) in this scope.
  def find(resource_class, name)
    name = name.to_s

    resource_class.ancestors.each do |c|
      next unless c.ancestors.include? RubyAdmin::Resource

      if @resources.has_key?(c) and @resources[c].has_key?(name)
        return @resources[c][name]
      end

      next unless @patterns.has_key? c

      @patterns[c].keys.sort.reverse.each do |priority|
        @patterns[c][priority].each do |pattern, block|
          next unless m = pattern.match(name)

          resource = c.send :instance_exec, name, *m.captures, &block

          unless resource.is_a? c
            raise RuntimeError, "resource returned by block for pattern #{pattern} is not a #{c}: #{resource.inspect}"
          end

          return resource
        end
      end
    end

    if parent
      return parent.find resource_class, name
    else
      return nil
    end
  end
end
