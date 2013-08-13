
# Atlassian JIRA API
#
# The SOAP API is documented here:
# https://docs.atlassian.com/rpc-jira-plugin/latest/com/atlassian/jira/rpc/soap/JiraSoapService.html
#
# == Example: Retrieve an existing issue
#   JIRA['https://jira.atlassian.com'].getIssue('CWD-1053')
class RubyAdmin::JIRA < RubyAdmin::Resource
  include RubyAdmin::Resource::Providable

  attr_accessor :endpoint, :username, :password

  def initialize(name, attributes = {})
    attributes[:endpoint] ||= name

    super(name, attributes)
  end

  def method_missing(method_name, *args, &block)
    provider.public_send(method_name, *args, &block)
  end
end

RubyAdmin::JIRA.provide :jira4r do
  def initialize(resource)
    if Gem::Version.new("#{RUBY_VERSION}") >= Gem::Version.new('1.9')
      gem 'jira4r-jh-ruby1.9', '>= 0.4.0'
    else
      gem 'jira4r-jh', '>= 0.4.0'
    end

    require 'jira4r/jira4r'

    api_version = 2
    base_url = resource.endpoint

    @api = Jira4R::JiraTool.new api_version, base_url

    ca_file = '/etc/ssl/certs/ca-certificates.crt'
    @api.driver.options['protocol.http.ssl_config.ca_file'] = ca_file

    # XXX: jira4r-jh (0.4.0) still prints debug output to STDOUT
    class << @api
      def puts(*args)
        # do nothing
      end
    end

    logger = Logger.new(STDERR)
    logger.level = Logger::ERROR
    @api.logger = logger

    if resource.username and resource.password
      @api.login resource.username, resource.password
    end

    super(resource)
  end

  def method_missing(method_name, *args, &block)
    @api.public_send(method_name, *args, &block)
  end
end
