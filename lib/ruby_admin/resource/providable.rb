
module RubyAdmin
  # +Resource::Providable+ is a module that can be included in a subclass
  # of +Resource+ to add the resource/provider-split behavioural pattern.
  #
  # Including this module will add the following to a resource class:
  # - Providable.provide class method
  # - :provider attribute
  # - #provider method
  module Resource::Providable

    # Class methods for subclasses of +Resource+ that include the
    # +Resource::Providable+ behaviour module.
    module ClassMethods
      def self.extended(resource_class)
        resource_class.instance_variable_set('@provider_classes', {})
      end

      # Define a named provider class for this +Resource+ class (or subclass).
      def provide(name, attributes = {}, &block)
        name = name.to_s

        if parent = attributes[:parent]
          attributes = attributes.clone
          parent_class = provider_class(parent)
          attributes.delete :parent
        else
          parent_class = Resource::Provider
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
      def provider_class(name)
        name = name.to_s
        @provider_classes[name] or raise "no such provider for #{self}: #{name}"
      end

      # Return all named provider classes for this resource class.
      def provider_classes
        @provider_classes.keys.map { |k| k.to_sym }
      end
    end

    def self.included(resource_class)
      resource_class.extend ClassMethods
    end

    attr_reader :provider

    def provider=(provider)
      @provider = self.class.provider_class(provider).new(self)
    end

    def initialize(name, attributes = {})
      # FIXME: should have a way for provider classes to return whether
      # they can handle the given resource or not, etc.  Just picking
      # the first one is definitely wrong in the long run.
      provider_classes = self.class.provider_classes

      if !provider_classes.empty?
        attributes = attributes.clone
        attributes[:provider] ||= provider_classes.sort.first
      end

      super(name, attributes)
    end

  end # Resource::Providable module
end # RubyAdmin module
