# Copyright (C) 2013 VMware, Inc.
require 'pathname'
module_lib    = Pathname.new(__FILE__).parent.parent.parent
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet_x/vmware/util'
require File.join module_lib, 'puppet_x/vmware/mapper_nsx'
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:nsx_edge_lb_pool) do
  @doc = 'Manage nsx edge loadbalancer pools'

  ensurable do
    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end

    defaultto(:present)

    def change_to_s(is, should)
      if should == :present
        provider.create_message
      else
        "removed"
      end
    end
  end

  newparam(:name, :namevar => true) do
    desc 'virtual Server name'
    newvalues(/\w/)
  end

  newparam(:scope_name) do
    desc 'edge name to configure'
    newvalues(/\w/)
  end

  newparam(:datacenter_name) do
    desc 'datacenter to search for when using groupingObjectIds'
    newvalues(/\w/)
  end

  map = PuppetX::VMware::MapperNsx.new_map('NsxEdgeLbPool')
  map.leaf_list.each do |leaf|
    option = {}
    if type_hash = leaf.olio[t = Puppet::Property::VMware_Array]
      option.update(
        :array_matching => :all,
        :parent => t
      )
    elsif type_hash = leaf.olio[t = Puppet::Property::VMware_Array_Hash]
      option.update(
        :parent => t
      )
    end  
    option.update(type_hash[:property_option]) if
        type_hash && type_hash[:property_option]

    newproperty(leaf.prop_name, option) do
      desc(leaf.desc) if leaf.desc
      newvalues(*leaf.valid_enum) if leaf.valid_enum
      munge {|val| leaf.munge.call(val)} if leaf.munge
      validate {|val| leaf.validate.call(val)} if leaf.validate
      eval <<-EOS
        def change_to_s(is,should)
          "[#{leaf.full_name}] changed \#{is_to_s(is).inspect} to \#{should_to_s(should).inspect}"
        end
      EOS
    end
  end

  autorequire(:transport) do
    self[:name]
  end
end
