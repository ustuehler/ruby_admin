source 'https://rubygems.org'

# Specify your gem's dependencies in ruby_admin.gemspec
gemspec

group :jira4r do
  if Gem::Version.new("#{RUBY_VERSION}") >= Gem::Version.new('1.9')
    gem 'jira4r-jh-ruby1.9', '>= 0.4.0'
  else
    gem 'jira4r-jh', '>= 0.4.0'
  end
end
