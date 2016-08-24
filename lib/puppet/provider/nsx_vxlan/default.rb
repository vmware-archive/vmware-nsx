# Copyright (C) 2014-2016 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'nsx')

Puppet::Type.type(:nsx_vxlan).provide(:default, :parent => Puppet::Provider::Nsx) do
  @doc = 'Manage VXLAN Virtual Wires.'

  def vxlan_wire
    @vxlan_wire ||= vxlan_wire_config(resource[:name])
  end

  def exists?
    vxlan_wire
  end

  def replace_properties
    data = {}
    Puppet::Type.type(:nsx_vxlan).parameters.collect.select {|x| x.to_s =~ /(name|description|tenant_id)/}.each do |prop|
      if resource[prop]
        camel_prop       = PuppetX::VMware::Util.camelize(prop, :lower)
        data[camel_prop] = resource[prop]
      end
    end
    data
  end

  def create
    scope_id = vdn_scope['id']
    post_url = "api/2.0/vdn/scopes/#{scope_id}/virtualwires"
    post(post_url, { 'virtualWireCreateSpec' => replace_properties } )
  end

  def destroy
    vwire_id = vxlan_wire['objectId']
    delete("api/2.0/vdn/virtualwires/#{vwire_id}")
  end

  def vdn_scope
    @vdn_scope ||= begin
      scope_url = '/api/2.0/vdn/scopes'
      results = ensure_array( nested_value(get(scope_url), %w{vdnScopes vdnScope}))
      scope = results.find{|vdnScope| vdnScope['id']}
      scope
    end
  end

end
