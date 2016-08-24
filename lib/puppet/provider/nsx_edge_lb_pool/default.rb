# Copyright (C) 2014-2016 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet_x/vmware/util'
require File.join vmware_module.path, 'lib/puppet/property/vmware'
module_lib    = Pathname.new(__FILE__).parent.parent.parent.parent
require File.join module_lib, 'puppet_x/vmware/mapper_nsx'
require File.join module_lib, 'puppet/provider/nsx'


Puppet::Type.type(:nsx_edge_lb_pool).provide(:nsx_edge_lb_pool, :parent => Puppet::Provider::Nsx) do
  @doc = 'Manage nsx edge load balancer vips.'

  ##### begin common provider methods #####
  # besides name, these methods should look exactly the same for all ensurable providers

  map ||= PuppetX::VMware::MapperNsx.new_map('NsxEdgeLbPool')

  define_method(:map) do 
    @map ||= map
  end

  def exists?
    # call exists? multiple times, settings won't change
    v ||= config_is_now and true
  end

  def create
    @flush_required = true
    @create_message ||= []
    # fetch properties from resource using provider setters
    map.leaf_list.each do |leaf|
      p = leaf.prop_name
      unless (value = @resource[p]).nil?
        self.send("#{p}=".to_sym, value)
        @create_message << "#{leaf.full_name} => #{value.inspect}"
      end
    end
  end

  def create_message
    @create_message ||= []
    "created using {#{@create_message.join ", "}}"
  end

  map.leaf_list.each do |leaf|
    define_method(leaf.prop_name) do
      value = PuppetX::VMware::MapperNsx::munge_to_tfsyms.call(
        PuppetX::VMware::Util::nested_value(config_is_now, leaf.path_is_now)
      )
    end

    define_method("#{leaf.prop_name}=".to_sym) do |value|
      nested_value_set config_should, leaf.path_should, value, transform_keys=false
      @flush_required = true
    end
  end

  def config_should
    @config_should ||= config_is_now || {}
  end

  ##### begin standard provider methods #####
  # these methods should exist in all ensurable providers, but content will diff

  def config_is_now
    @config_is_now ||= 
      begin
        url     = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/pools"
        results = ensure_array(nested_value(get(url), [ 'loadBalancer', 'pool' ]) )
        pool    = results.find {|x| x['name'] == resource[:name] }
        return nil unless pool
        config  = { 'pool' => pool }
        config
      end
  end

  def prep_flush(config)
    members = nested_value(config,['pool','member'])
    members.each do |member| 
      port             = nested_value(member,['port']).to_i
      valid_port_range = [*1..65535]
      unless port and valid_port_range.include?(port)
        msg = "a valid port number(1-65535) is required for a member: #{member}"
        raise Puppet::Error, msg
      end
    end
  end

  def flush
    if @flush_required 
      config = map.prep_for_serialization config_should
      prep_flush(config)

      if exists?
        id   = config['pool']['poolId']
        url  = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/pools/#{id}"
        put  url, config
      else
        url  =  "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/pools"
        post url, config
      end
    end
  end

  def destroy
    id  = config_is_now['pool']['poolId']
    url = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/pools/#{id}"
    delete(url)
  end

  ##### begin misc provider specific methods #####
  # This section is for overrides of automatically-generated property getters and setters. Many
  # providers don't need any overrides. The most common use of overrides is to allow user input
  # of component names instead of object IDs (REST APIs) or Managed Object References (SOAP APIs).

  # using monitorId, find the name
  alias get_pool_monitor_id pool_monitor_id
  def pool_monitor_id
    id = get_pool_monitor_id
    return nil if id.nil?
    result = all_monitors.find{|x| x['monitorId'] == id }
    unless result
      msg = "\nSomething went wrong, the monitor id: '#{id}' was not found\n"
      raise Puppet::Error, msg
    end
    result['name']
  end

  # using the name, find the monitorId
  alias set_pool_monitor_id pool_monitor_id=
  def pool_monitor_id=(name)
    result = all_monitors.find{|x| x['name'] == name}
    unless result
      # provide a list of available applicationProiles if the one specified does not exist
      avail_names   = all_monitors.collect{|x| x['name']}
      not_found_msg = "\nThe monitor: '#{name}' was not found, available ones are: #{avail_names}\n"
      raise Puppet::Error, not_found_msg
    end
    set_pool_monitor_id result['monitorId']
  end

  # using applicationRuleId, find the name
  alias get_pool_application_rule_id pool_application_rule_id
  def pool_application_rule_id
    id = get_pool_application_rule_id
    return nil if id.nil?
    result = all_application_rules.find{|x| x['applicationRuleId'] == id }
    unless result
      msg = "\nSomething went wrong, the application rule id: '#{id}' was not found\n"
      raise Puppet::Error, msg
    end
    result['name']
  end

  # using the name, find the applicationRuleId
  alias set_pool_application_rule_id pool_application_rule_id=
  def pool_application_rule_id=(name)
    result = all_application_rules.find{|x| x['name'] == name}
    unless result
      # provide a list of available applicationProiles if the one specified does not exist
      avail_names   = all_application_rules.collect{|x| x['name']}
      not_found_msg = "\nThe monitor: '#{name}' was not found, available ones are: #{avail_names}\n"
      raise Puppet::Error, not_found_msg
    end
    set_pool_application_rule_id result['applicationRuleId']
  end

  alias get_pool_member pool_member
  def pool_member
    new_members = Array.new
    members     = ensure_array(get_pool_member)
    unique_members_name_check(members,'current')
    # replace the groupingObjectId with the name and prefix
    # eg. vm:vm1,dvportgroup:dvportgroup1,network:portgroup1
    members.each do |member|
      name = member['name']
      next if name.nil?
      if member.has_key?('groupingObjectId')
        obj = get_pool_member.find{|x| x['name'] == name}
        next if obj.nil?
        id  = obj['groupingObjectId']
        member['groupingObjectId'] = vim_id_to_name(id)
      end
      new_members << member
    end
    new_members
  end

  alias set_pool_member pool_member=
  def pool_member=(members)
    new_members = Array.new
    members     = ensure_array(members)
    unique_members_name_check(members,'new')
    members.each do |member|
      # require the key: 'name', even though api say's optional with ipAddress, we are requiring
      msg1 = 'a unique "name" key must specified for each member.'
      msg2 = 'ex pool => { member => [ { name = "member1", ipAddress => .... }]}'
      msg  = msg1 + msg2
      raise Puppet::Error, (msg) unless member.has_key?('name')
      # replace the groupingObjectId name with the objectId
      if member.has_key?('groupingObjectId')
        name_and_type              = member['groupingObjectId']
        member['groupingObjectId'] = vim_name_to_id(name_and_type)
      end
      new_members << member
    end
    set_pool_member new_members
  end

  ##### begin private provider specific methods section #####
  # These methods are provider specific and that can be private
  private

  def vim_name_to_id(name_and_type)
    type, name = name_and_type.split(':')
    case type.to_s
    when 'vm'
      result      = vm_id_from_name(name)
    when 'network'
      result      = portgroup_id_from_name(name,'Network')
    when 'dvportgroup'
      result      = portgroup_id_from_name(name,'DistributedVirtualPortgroup')
    else
      msg = "\nInvalid object type, valid types are: vm/network/dvportgroup\n"
      raise Puppet::Error, msg
    end
    unless result
      msg = "\nThe virtual center object: '#{name}' was not found\n"
      raise Puppet::Error, msg
    end
    result
  end

  def vim_id_to_name(id)
    # for different object types, search and substitute the appropriate name
    # common methods can be found in lib/puppet/provider/nsx.rb
    case id
    when /^dvportgroup-/
      new_id = 'dvportgroup:' + portgroup_name_from_id(id,'DistributedVirtualPortgroup')
    when /^network-/
      new_id = 'network:'     + portgroup_name_from_id(id,'Network')
    when /^vm-/
      new_id = 'vm:'          + vm_name_from_id(id)
    else
      raise Puppet::Error "Unrecognized id type: #{id}, valid prefix's are dvportgroup/network/vm\n"
    end
    new_id
  end

  # since we are using name to compare array_hash, ensure they are unique for substitution
  def unique_members_name_check(members,location)
    used = {}
    members.each do |member|
      name = member['name']
      if used.has_key?(name)
        msg = "member => name: #{name} is used more than once in #{location} config, please update so the names are unique"
        raise Puppet::Error, msg
      end
      used[name] = name
    end
  end

  def all_monitors
    @all_monitor ||=
      begin
        url = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/monitors"
        ensure_array( nested_value(get(url), [ 'loadBalancer', 'monitor' ]) )
      end 
  end

  def all_application_rules
    @all_application_rules ||=
      begin
        url = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/applicationrules"
        ensure_array( nested_value(get(url), [ 'loadBalancer', 'applicationRule' ]) )
      end 
  end

end
