source 'https://rubygems.org'

gem 'gyoku'
gem 'hashdiff'
gem 'nori'
gem 'rest-client'
gem 'rbvmomi'

group :development, :test do
  gem 'rake'
  gem 'rspec', "~> 2.11.0", :require => false
  gem 'mocha', "~> 0.10.5", :require => false
  gem 'puppetlabs_spec_helper', :require => false
  gem 'rspec-puppet', :require => false
  gem 'puppet-lint'
end

puppetversion = ENV.key?('PUPPET_VERSION') ? ENV['PUPPET_VERSION'] : ['>= 3.3']
gem 'puppet', puppetversion
gem 'facter', '>= 1.7.0'
