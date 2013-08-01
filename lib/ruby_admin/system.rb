
module RubyAdmin
  class System < Resource
    attr_accessor :hostname, :username, :password

    def initialize(name, attributes = {})
      attributes[:hostname] ||= name

      super(name, attributes)
    end

    # Execute a system command on the designated system.
    def sh(command)
      provider.sh command
    end

    provide :local do
      def sh(command)
        system(command)
      end
    end

    provide :ssh do
      def initialize(resource)
        require 'net/ssh'

        super(resource)
      end

      def default_username
        require 'etc'

        Etc.getlogin
      end

      def ssh
        options = {}
        username = @resource.username || default_username
        options[:password] = @resource.password if @resource.password
        Net::SSH.start @resource.hostname, username, options
      end

      def sh(command)
        puts ssh.exec!(command)
      end
    end

    match %r{^(?:([^@:]*)(?::([^@]*))?@)?([A-Za-z0-9.-]+)$},
      :priority => -1 do |name, username, password, hostname|

      new name,
        :provider => hostname == 'localhost' ? :local : :ssh,
        :hostname => hostname,
        :username => username,
        :password => password
    end
  end
end
