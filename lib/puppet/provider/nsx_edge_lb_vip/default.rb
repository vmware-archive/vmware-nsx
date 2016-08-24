# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet_x/vmware/util'
require File.join vmware_module.path, 'lib/puppet/property/vmware'
module_lib    = Pathname.new(__FILE__).parent.parent.parent.parent
require File.join module_lib, 'puppet_x/vmware/mapper_nsx'
require File.join module_lib, 'puppet/provider/nsx'


Puppet::Type.type(:nsx_edge_lb_vip).provide(:nsx_edge_lb_vip, :parent => Puppet::Provider::Nsx) do
  @doc = 'Manage nsx edge load balancer vips.'

  ##### begin common provider methods #####
  # besides name, these methods should look exactly the same for all ensurable providers

  map ||= PuppetX::VMware::MapperNsx.new_map('NsxEdgeLbVip')

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
        url     = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/virtualservers"
        results = ensure_array(nested_value(get(url), [ 'loadBalancer', 'virtualServer' ]) )
        vs      = results.find {|vip| vip['name'] == resource[:name] }
        return nil unless vs
        config  = { 'virtualServer' => vs }
        config
      end
  end

  def flush
    if @flush_required 
      config = map.prep_for_serialization config_should

      if exists?
        id   = config['virtualServer']['virtualServerId']
        url  = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/virtualservers/#{id}"
        put  url, config
      else
        url  =  "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/virtualservers"
        post url, config
      end
    end
  end

  def destroy
    id  = config_is_now['virtualServer']['virtualServerId']
    url = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/virtualservers/#{id}"
    delete(url)
  end

  ##### begin misc provider specific methods #####
  # This section is for overrides of automatically-generated property getters and setters. Many
  # providers don't need any overrides. The most common use of overrides is to allow user input
  # of component names instead of object IDs (REST APIs) or Managed Object References (SOAP APIs).

  # using applicationProfileId, find the name
  alias get_virtual_server_application_profile_id virtual_server_application_profile_id
  def virtual_server_application_profile_id
    id = get_virtual_server_application_profile_id
    return nil if id.nil?
    result = all_app_profs.find{|x| x['applicationProfileId'] == id }
    unless result
      not_found_msg = "\nSomething went wrong, the app profile id: '#{id}' was not found\n"
      raise Puppet::Error, not_found_msg
    end
    result['name']
  end

  # using the name, find the applicationProfileId
  alias set_virtual_server_application_profile_id virtual_server_application_profile_id=
  def virtual_server_application_profile_id=(name)
    result        = all_app_profs.find{|x| x['name'] == name}
    unless result
      # provide a list of available applicationProiles if the one specified does not exist
      avail_names   = all_app_profs.collect{|x| x['name']}
      not_found_msg = "\nThe applicationProfile: '#{name}' was not found, available ones are: #{avail_names}\n"
      raise Puppet::Error, not_found_msg
    end
    set_virtual_server_application_profile_id result['applicationProfileId']
  end

  # using applicationRuleId, find the name
  alias get_virtual_server_application_rule_id virtual_server_application_rule_id
  def virtual_server_application_rule_id
    id = get_virtual_server_application_rule_id
    return nil if id.nil?
    result = all_app_rules.find{|x| x['applicationRuleId'] == id }
    unless result
      not_found_msg = "\nSomething went wrong, the app rule id: '#{id}' was not found\n"
      raise Puppet::Error, not_found_msg
    end
    result['name']
  end

  # using the name, find the applicationRuleId
  alias set_virtual_server_application_rule_id virtual_server_application_rule_id=
  def virtual_server_application_rule_id=(name)
    result        = all_app_rules.find{|x| x['name'] == name}
    unless result
      # provide a list of available applicationProiles if the one specified does not exist
      avail_names   = all_app_rules.collect{|x| x['name']}
      not_found_msg = "\nThe applicationRule: '#{name}' was not found, available ones are: #{avail_names}\n"
      raise Puppet::Error, not_found_msg
    end
    set_virtual_server_application_rule_id result['applicationRuleId']
  end

  # using defaultPoolId, find the name
  alias get_virtual_server_default_pool_id virtual_server_default_pool_id
  def virtual_server_default_pool_id
    id = get_virtual_server_default_pool_id
    return nil if id.nil?
    result = all_pools.find{|x| x['poolId'] == id }
    unless result
      not_found_msg = "\nSomething went wrong, the pool id: '#{id}' was not found\n"
      raise Puppet::Error, not_found_msg
    end
    result['name']
  end

  # using the name, find the defaultPoolId
  alias set_virtual_server_default_pool_id virtual_server_default_pool_id=
  def virtual_server_default_pool_id=(name)
    result        = all_pools.find{|x| x['name'] == name}
    unless result
      # provide a list of available pools if the one specified does not exist
      avail_names   = all_pools.collect{|x| x['name']}
      not_found_msg = "\nThe pool: '#{name}' was not found, available ones are: #{avail_names}\n"
      raise Puppet::Error, not_found_msg
    end
    set_virtual_server_default_pool_id result['poolId']
  end

  

  ##### begin private provider specific methods section #####
  # These methods are provider specific and that can be private
  private

  def all_app_profs
    @all_app_profs ||=
      begin
        url = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/applicationprofiles"
        ensure_array( nested_value(get(url), [ 'loadBalancer', 'applicationProfile' ]) )
      end
  end

  def all_app_rules
    @all_app_rules ||=
      begin
        url = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/applicationrules"
        ensure_array( nested_value(get(url), [ 'loadBalancer', 'applicationRule' ]) )
      end
  end

  def all_pools
    @all_pools ||=
      begin
        url = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/pools"
        ensure_array( nested_value(get(url), [ 'loadBalancer', 'pool' ]) )
      end 
  end

end
