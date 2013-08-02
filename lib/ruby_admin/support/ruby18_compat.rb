# Emulate Ruby 1.9 behavior in Ruby 1.8.

module Kernel
  unless defined? singleton_class
    # Emulate Ruby 1.9 Kernel.singleton_class.
    def singleton_class
      (class << self; self; end)
    end
  end

  unless defined? define_singleton_method
    # Emulate Ruby 1.9 Kernel.define_singleton_method.
    def define_singleton_method(name, *args, &block)
      singleton_class.send :define_method, name, *args, &block
    end
  end
end
