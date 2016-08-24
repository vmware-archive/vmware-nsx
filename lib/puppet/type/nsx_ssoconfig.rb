# Copyright (C) 2014-2016 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:nsx_ssoconfig) do
  @doc = 'Manage NSX SSO/Lookup Service configuration'

  ensurable

  newproperty(:sso_lookup_service_url) do
    desc 'URL to the lookup service, i.e. https://<vc_fqdn>:7444/lookupservice/sdk'
  end

  newproperty(:sso_admin_username) do
    desc 'Username used to connect to lookup service'
  end

  newparam(:name, :namevar => true) do
    desc 'resource name'
  end

  newparam(:sso_admin_userpassword) do
    desc 'Password used to connect to lookup service'
  end

  newparam(:sso_lookup_service_thumbprint) do
    desc 'Certificate thumbprint of the destination service'
  end
end
