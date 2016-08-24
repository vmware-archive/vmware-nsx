# Copyright (C) 2014-2016 VMware, Inc.
[ 'puppet_x/puppetlabs/transport',
  'puppet_x/vmware/util' ].each do |path|
  begin
    require path
  rescue LoadError => detail
    require 'pathname' # WORK_AROUND #14073 and #7788
    vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
    require File.join vmware_module.path, "lib/#{path}"
  end
end

begin
  require 'puppet_x/puppetlabs/transport/nsx'
rescue LoadError => detail
  require 'pathname' # WORK_AROUND #14073 and #7788
  module_lib = Pathname.new(__FILE__).parent.parent.parent
  require File.join module_lib, 'puppet_x/puppetlabs/transport/nsx'
end

begin
  require 'puppet_x/puppetlabs/transport/vsphere'
rescue LoadError => detail
  require 'pathname' # WORK_AROUND #14073 and #7788
  vcenter_module = Puppet::Module.find('vcenter', Puppet[:environment].to_s)
  require File.join vcenter_module.path, 'lib/puppet_x/puppetlabs/transport/vsphere'
end


if Puppet.features.nsx? and ! Puppet.run_mode.master?
  # Using Savon's library:
  require 'nori'
  require 'gyoku'
end

# TODO: Depending on number of shared methods, we might make Puppet::Provider::Vcenter parent:
class Puppet::Provider::Nsx <  Puppet::Provider
  confine :feature => :nsx

  def rest
    @transport ||= PuppetX::Puppetlabs::Transport.retrieve(:resource_ref => resource[:transport], :catalog => resource.catalog, :provider => 'nsx')
    @transport.rest
  end

  [:get, :delete].each do |m|
    define_method(m) do |url|
      begin
        result = Nori.parse(rest[url].send(m))
      rescue RestClient::Exception => e
        raise Puppet::Error, "\n#{e.exception}:\n#{e.response}"
      end
      Puppet.debug "NSX REST API #{m} #{url} result:\n#{result.inspect}"
      result
    end
  end

  [:put, :post].each do |m|
    define_method(m) do |url, data|
      begin
        result = rest[url].send(m, Gyoku.xml(data), :content_type => 'application/xml; charset=UTF-8')
      rescue RestClient::Exception => e
        Puppet.debug "Failed REST #{m} to URL #{url}:\n#{data}\nXML Format:\n#{Gyoku.xml data}"
        raise Puppet::Error, "\n#{e.exception}:\n#{e.response}"
      end
      Puppet.debug "NSX REST API #{m} #{url} with #{data.inspect} result:\n#{result.inspect}"
      result
    end
  end

  # We need the corresponding vCenter connection once NSX is connected
  def vim
    @vsphere_transport ||= PuppetX::Puppetlabs::Transport.retrieve(:resource_hash => connection, :provider => 'vsphere')
    @vsphere_transport.vim
  end

  def connection
    server = vc_info['ipAddress']
    raise Puppet::Error, "vSphere API connection failure: NSX #{resource[:transport]} not connected to vCenter." unless server
    connection = resource.catalog.resources.find{|x| x.class == Puppet::Type::Transport && x[:server] == server}
    raise Puppet::Error, "vSphere API connection failure: Linked vCenter in NSX Manager does not match hostname/ipaddress specification: #{server}" unless connection
    connection.to_hash
  end

  def vc_info
    @vc_info ||= get('api/2.0/global/config')['vsmGlobalConfig']['vcInfo']
  end

  def nested_value *args, &block
    PuppetX::VMware::Util.nested_value *args, &block
  end

  def nested_value_set *args
    PuppetX::VMware::Util::nested_value_set *args
  end

  def ensure_array(value)
    # Ensure results an array. If there's a single value the result is a hash, while multiple results in an array.
    case value
    when nil
      []
    when Array
      value
    when Hash
      [value]
    when Nori::StringWithAttributes
      [value]
    else
      raise Puppet::Error, "Unknown type for munging #{value.class}: '#{value}'"
    end
  end

  def edge_summary
    # TODO: This may exceed 256 pagesize limit.
    @edge_summary ||= ensure_array( nested_value( get('api/3.0/edges'), ['pagedEdgeList', 'edgePage', 'edgeSummary'] ) )
  end

  def edge_detail
    raise Puppet::Error, "edge not available" unless @instance
    @edge_detail ||= nested_value(get("api/3.0/edges/#{@instance['id']}"), ['edge'])
  end

  def datacenter(name=resource[:datacenter_name])
    dc = vim.serviceInstance.find_datacenter(name) or raise Puppet::Error, "datacenter '#{name}' not found."
    dc
  end

  def datacenter_moref(name=resource[:datacenter_name])
    dc = datacenter
    dc._ref
  end

  def vxlan_wire_config(vxlan_wire_name)
    wire_url = '/api/2.0/vdn/virtualwires'
    results = ensure_array( nested_value(get(wire_url), %w{virtualWires dataPage virtualWire}))
    wire_config = results.find{|virtualWire| virtualWire['name'] == vxlan_wire_name}
    wire_config
  end

  def portgroup_moref(portgroup, islogical=false)
    if islogical
      result = vxlan_wire_config(portgroup)
      raise(Puppet::Error, "Fatal Error: Logical switch portgroup: '#{portgroup}' was not found") if result.nil?
      result['objectId']
    else
      result = datacenter.network.find{|pg| pg.name == portgroup }
      raise(Puppet::Error, "Fatal Error: Portgroup: '#{portgroup}' was not found") if result.nil?
      result._ref
    end
  end

  def dvswitch(name=resource[:switch]['name'])
    @dvswitch ||= begin
      dvswitches = datacenter.networkFolder.children.select {|n|
        n.class == RbVmomi::VIM::VmwareDistributedVirtualSwitch
      }
      dv = dvswitches.find{|d| d.name == name}
      raise Puppet::Error, "dvswitch: #{name} was not found" if dv.nil?
      dv
    end
  end

  def avail_scopes
    @avail_scopes ||= get('api/2.0/services/usermgmt/scopingobjects')['scopingObjects']['object']
  end

  def nsx_scope_moref(type=resource[:scope_type], name=resource[:scope_name])
    type_name    = PuppetX::VMware::Util.camelize(type.to_s, :upper)
    # one off since first letter in global is upper case
    name         = 'Global' if type_name == 'GlobalRoot'
    instance     = avail_scopes.find{|x| x['objectTypeName'] == type_name and x['name'] == name}
    raise Puppet::Error, "scope: #{name} or type: #{type.to_s} not found" unless instance
    instance['objectId']
  end

  def nsx_edge_moref(name=resource[:scope_name])
    edges = edge_summary || []
    instance = edges.find{|x| x['name'] == name}
    raise Puppet::Error, "NSX Edge #{name} does not exist." unless instance
    instance['id']
  end

  # detect if nsx or vsm
  def network_manager_version
    @network_manager_version ||=
      begin
        url_path = 'api/1.0/appliance-management/global/info'
        version_info = nested_value(get(url_path),['globalInfo','versionInfo']).select{|x| x =~ /Version/}.values.join('.')
      rescue
        # if this get works, assume 5.x is good
        get('api/2.0/global/config')
        version_info = '5.x'
      end
  end

  def all_vms
    @all_vms ||=
      begin
        vms = datacenter.vmFolder.inventory_flat('VirtualMachine' => [ 'name' ])
        vms.select{|obj, props| obj.is_a?(VIM::VirtualMachine)}
      end
  end

  def vm_name_from_id(id)
    vm = all_vms.find{|x| x[0]._ref == id} 
    msg = "No vm with the id of: #{id} was found\n"
    raise Puppet::Error, msg if vm.nil?
    vm[0].name
  end

  def vm_id_from_name(name)
    vm = all_vms.find{|x| x[0].name == name} 
    msg = "No vm with the name of: #{name} was found\n"
    raise Puppet::Error, msg if vm.nil?
    vm[0]._ref
  end

  def all_portgroups
    datacenter.network
  end

  def portgroup_name_from_id(id,type)
    pg  = all_portgroups.find{|x| x._ref == id and x.class.to_s == type} 
    msg = "No portgroup with the id: #{id} with the type: #{type} was found\n"
    raise Puppet::Error, msg if pg.nil?
    pg.name
  end

  def portgroup_id_from_name(name,type)
    pg  = all_portgroups.find{|x| x.name == name and x.class.to_s == type} 
    msg = "No portgroup with the name: #{name} of the type: #{type} was found\n"
    raise Puppet::Error, msg if pg.nil?
    pg._ref
  end

end
