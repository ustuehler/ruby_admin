
module RubyAdmin
  class Service < Resource
    attr_accessor :system, :service_name

    def status
      provider.status
    end

    def restart
      provider.restart
    end

    provide :debian do
      def status
        resource.system.sh "/usr/sbin/service #{resource.service_name} status"
      end

      def restart
        resource.system.sh "/usr/sbin/service #{resource.service_name} restart"
      end
    end

    match %r{^([^/]+)/(.+)$} do |full_name, system_name, service_name|
      new full_name,
        :system => System[system_name],
        :service_name => service_name
    end
  end
end
