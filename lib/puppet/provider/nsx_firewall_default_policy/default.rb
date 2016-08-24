require 'pathname'
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'nsx')


Puppet::Type.type(:nsx_firewall_default_policy).provide(:default, :parent => Puppet::Provider::Nsx) do
  @doc = 'Manages NSX firewall default policy'

  def edge_policy
    @edge_policy ||= begin
      policy_url = "api/4.0/edges/#{nsx_edge_moref}/firewall/config/defaultpolicy"
      get(policy_url)['firewallDefaultPolicy']
    end
  end

  Puppet::Type.type(:nsx_firewall_default_policy).properties.collect{|x| x.name}.reject{|x| x == :ensure}.each do |prop|
    camel_prop = PuppetX::VMware::Util.camelize(prop, :lower)
    define_method(prop) do
      v = edge_policy[camel_prop]
      v = :false if FalseClass === v
      v = :true  if TrueClass  === v
      v
    end

    define_method("#{prop}=".to_sym) do |value|
      edge_policy[camel_prop] = value
      @pending_changes = true
    end
  end

  def flush
    if @pending_changes
      raise Puppet::Error, "policy not found for #{resource[:name]}" unless edge_policy
      put_url = "api/4.0/edges/#{nsx_edge_moref}/firewall/config/defaultpolicy"
      Puppet.debug("Updating default policy for edge: #{resource[:name]}")
      put("#{put_url}", {'firewallDefaultPolicy' => edge_policy})
    end
  end
end
