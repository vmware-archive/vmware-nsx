# Copyright (C) 2014 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'nsx')

Puppet::Type.type(:nsx_ssoconfig).provide(:default, :parent => Puppet::Provider::Nsx) do
  @doc = 'Manages NSX SSO/Lookup Service settings.'

  Puppet::Type.type(:nsx_ssoconfig).properties.collect{|x| x.name}.each do |prop|
    camel_prop = PuppetX::VMware::Util.camelize(prop, :lower)

    define_method(prop) do
      value = current[camel_prop] if current
      Puppet.debug "#{prop} (#{camel_prop}) set to #{value}"
      case value
      when TrueClass  then :true
      when FalseClass then :false
      else value
      end
    end

    define_method("#{prop}=") do |value|
      @update = true
    end
  end

  def create
    set
  end

  def destroy
    delete('/api/2.0/services/ssoconfig')
  end

  def exists?
    !current.nil?
  end

  def flush
    set if @update
  end

  def current
    @current ||= get('/api/2.0/services/ssoconfig')['ssoConfig']
  end

  def set
    data = {
      :ssoLookupServiceUrl     => resource[:sso_lookup_service_url],
      :ssoAdminUsername        => resource[:sso_admin_username],
      :ssoAdminUserpassword    => resource[:sso_admin_userpassword],
      :certificateThumbprint   => resource[:sso_lookup_service_thumbprint]
    }
    nsx_catch( post("/api/2.0/services/ssoconfig", {:ssoConfig => data} ) )
  end

  def nsx_catch(result)
    message = Nori.parse(result)
    message.each do |key, value|
      raise Puppet::Error, "NSX Configuration Failure: #{value['message']}" if !value['status']
    end
  end
end
