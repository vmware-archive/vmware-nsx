# Copyright (C) 2014-2016 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:nsx_vxlan) do
  @doc = 'Manage NSX VXLAN Virtual Wires.'

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
    desc 'virtual wire name'
    newvalues(/\w/)
  end

  newparam(:description) do
    desc 'virtual wire description'
    newvalues(/\w/)
  end

  newparam(:tenant_id) do
    desc 'virtual wire tenant id'
    newvalues(/\w/)
  end

  autorequire(:nsx_vxlan_scope) do
    self[:name]
  end

  autorequire(:transport) do
    self[:name]
  end

end
