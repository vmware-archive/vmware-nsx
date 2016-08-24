# Copyright (C) 2014 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet_x/vmware/util'
require File.join vmware_module.path, 'lib/puppet/property/vmware'
module_lib    = Pathname.new(__FILE__).parent.parent.parent.parent
require File.join module_lib, 'puppet_x/vmware/mapper_nsx'
require File.join module_lib, 'puppet/provider/nsx'


Puppet::Type.type(:nsx_edge_lb_monitor).provide(:nsx_edge_lb_monitor, :parent => Puppet::Provider::Nsx) do
  @doc = 'Manage nsx edge load balancer monitors.'

  ##### begin common provider methods #####
  # besides name, these methods should look exactly the same for all ensurable providers

  map ||= PuppetX::VMware::MapperNsx.new_map('NsxEdgeLbMonitor')

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
        url     = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/monitors"
        results = ensure_array(nested_value(get(url), [ 'loadBalancer', 'monitor' ]) )
        monitor = results.find {|x| x['name'] == resource[:name] }
        return nil unless monitor
        config  = { 'monitor' => monitor }
        config
      end
  end

  def flush
    if @flush_required 
      config = map.prep_for_serialization config_should

      if exists?
        id   = config['monitor']['monitorId']
        url  = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/monitors/#{id}"
        put  url, config
      else
        url  =  "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/monitors"
        post url, config
      end
    end
  end

  def destroy
    id  = config_is_now['monitors']['monitorId']
    url = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/monitors/#{id}"
    delete(url)
  end

  ##### begin misc provider specific methods #####
  # This section is for overrides of automatically-generated property getters and setters. Many
  # providers don't need any overrides. The most common use of overrides is to allow user input
  # of component names instead of object IDs (REST APIs) or Managed Object References (SOAP APIs).

  ##### begin private provider specific methods section #####
  # These methods are provider specific and that can be private
  private

end
