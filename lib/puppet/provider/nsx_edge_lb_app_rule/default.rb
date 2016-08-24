# Copyright (C) 2014-2016 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet_x/vmware/util'
require File.join vmware_module.path, 'lib/puppet/property/vmware'
module_lib    = Pathname.new(__FILE__).parent.parent.parent.parent
require File.join module_lib, 'puppet_x/vmware/mapper_nsx'
require File.join module_lib, 'puppet/provider/nsx'


Puppet::Type.type(:nsx_edge_lb_app_rule).provide(:nsx_edge_lb_app_rule, :parent => Puppet::Provider::Nsx) do
  @doc = 'Manage nsx edge load balancer application rule settings.'

  ##### begin common provider methods #####
  # besides name, these methods should look exactly the same for all ensurable providers

  map ||= PuppetX::VMware::MapperNsx.new_map('NsxEdgeLbAppRule')

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
        rule    = all_app_rules.find {|x| x['name'] == resource[:name] }
        return nil unless rule
        config  = { 'applicationRule' => rule }
        config
      end
  end

  def flush
    if @flush_required 
      config = map.prep_for_serialization config_should
      if exists?
        id   = config['applicationRule']['applicationRuleId']
        url  = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/applicationrules/#{id}"
        put  url, config
      else
        url  =  "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/applicationrules"
        post url, config
      end
    end
  end

  def destroy
    id  = config_is_now['applicationRule']['applicationRuleId']
    url = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/applicationrules/#{id}"
    delete(url)
  end

  ##### begin misc provider specific methods #####
  # This section is for overrides of automatically-generated property getters and setters. Many
  # providers don't need any overrides. The most common use of overrides is to allow user input
  # of component names instead of object IDs (REST APIs) or Managed Object References (SOAP APIs).

  # using applicationRuleId, find the name
  def application_rule_id
    id = get_application_rule_id
    return nil if id.nil?
    result = all_app_rules.find{|x| x['applicationRuleId'] == id }
    unless result
      msg = "\nSomething went wrong, the app rule id: '#{id}' was not found\n"
      raise Puppet::Error, msg
    end
    result['name'] 
  end
  alias get_application_rule_id application_rule_id

  # using the name, find the applicationRuleId
  def application_rule_id=(name)
    result = all_app_rules.find{|x| x['name'] == name}
    unless result
      # provide a list of available applicationProiles if the one specified does not exist
      avail_names   = all_app_rules.collect{|x| x['name']}
      not_found_msg = "\nThe app rule: '#{name}' was not found, available are: #{avail_names}\n"
      raise Puppet::Error, not_found_msg
    end
    set_application_rule_id result['applicationRuleId']
  end
  alias set_application_rule_id application_rule_id=

  ##### begin private provider specific methods section #####
  # These methods are provider specific and that can be private
  private

  def all_app_rules
    @all_app_rules ||=
      begin
        url = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/applicationrules"
        ensure_array( nested_value(get(url), [ 'loadBalancer', 'applicationRule' ]) )
      end
  end

end
