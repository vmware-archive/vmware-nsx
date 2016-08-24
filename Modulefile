name         'vmware-nsx'
source       'git@github.com:vmware/vmware-nsx.git'
author       'VMware'
license      'Apache 2.0'
summary      'VMware NSX puppet module'
description  'VMware NSX resource management.'
project_page 'https://github.com/vmware/vmware-nsx'

moduledir = File.dirname(__FILE__)
ENV['GIT_DIR'] = moduledir + '/.git'

git_version = %x{git describe --dirty --tags}.chomp.split('-')[0]
unless $?.success? and git_version =~ /^\d+\.\d+\.\d+/
  raise "Unable to determine version using git: #{$?} => #{git_version.inspect}"
end
version    git_version

