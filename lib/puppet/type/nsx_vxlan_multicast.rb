# Copyright (C) 2014 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:nsx_vxlan_multicast) do
  @doc = 'Manage NSX VXLAN Multicast Address Ranges.'

  ensurable do
    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end

    defaultto(:present)
  end

  newparam(:name, :namevar => true) do
    desc 'switch name'
    newvalues(/\w/)
  end

  newparam(:id) do
    desc 'multicast id'
    newvalues(/\d/)
  end

  newparam(:desc) do
    desc 'multicast description'
    newvalues(/\w/)
  end

  newparam(:begin) do
    desc 'multicast start range'
    newvalues(/\d/)
  end

  newparam(:end) do
    desc 'multicast end range'
    newvalues(/\d/)
  end

  autorequire(:nsx_vxlan_segment) do
    self[:name]
  end

  autorequire(:transport) do
    self[:name]
  end

end
