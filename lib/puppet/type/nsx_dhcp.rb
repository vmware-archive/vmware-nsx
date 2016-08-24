# Copyright (C) 2014-2016 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'
require 'ruby-debug'

Puppet::Type.newtype(:nsx_dhcp) do
  @doc = 'Manage NSX Edge DHCP'
  
  newparam(:scope_name, :namevar => true) do
    desc 'dhcp name'
  end
  
  newproperty(:dhcp_pools, :array_matching => :all, :key => 'ipRange', :parent => Puppet::Property::VMware_Array_Hash ) do
    desc 'these are ip_pools used for dhcp'
    defaultto([])
  end
  
  newproperty(:dhcp_bindings, :array_matching => :all, :key => 'ipAddress', :parent => Puppet::Property::VMware_Array_Hash ) do
    desc 'static bindings for dhcp'
    defaultto([])
  end
  
  newproperty(:dhcp_logging, :parent => Puppet::Property::VMware_Hash ) do
    desc 'manage logging for dhcp'
    defaultto([])
  end

  newproperty(:dhcp_enabled) do
    desc 'whether or not the DHCP service is enabled'
    newvalues(:true, :false)
    defaultto(:false)
  end
  
  newparam(:datacenter_name, :parent => Puppet::Property::VMware) do
  end

  autorequire(:nsx_edge) do
    self[:name]
  end

end
