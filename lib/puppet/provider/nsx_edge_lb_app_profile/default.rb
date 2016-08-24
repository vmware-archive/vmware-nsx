# Copyright (C) 2014-2016 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet_x/vmware/util'
require File.join vmware_module.path, 'lib/puppet/property/vmware'
module_lib    = Pathname.new(__FILE__).parent.parent.parent.parent
require File.join module_lib, 'puppet_x/vmware/mapper_nsx'
require File.join module_lib, 'puppet/provider/nsx'


Puppet::Type.type(:nsx_edge_lb_app_profile).provide(:nsx_edge_lb_app_profile, :parent => Puppet::Provider::Nsx) do
  @doc = 'Manage nsx edge load balancer vips.'

  ##### begin common provider methods #####
  # besides name, these methods should look exactly the same for all ensurable providers

  map ||= PuppetX::VMware::MapperNsx.new_map('NsxEdgeLbAppProfile')

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
        url     = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/applicationprofiles"
        results = ensure_array(nested_value(get(url), [ 'loadBalancer', 'applicationProfile' ]) )
        res     = results.find{|x| x['name'] == resource[:name] }
        return nil unless res
        config  = { 'applicationProfile' => res }
        config
      end
  end

  def prep_flush(config)
    # bz: 1373463, nsx api doesn't error if you send an invalid combination, but instead does not set persistence
    if config['applicationProfile']['persistence'] and config['applicationProfile']['persistence'].has_key?('method')
      method          = nested_value(config, ['applicationProfile', 'persistence', 'method']).to_s
      ssl_passthrough = nested_value(config,  ['applicationProfile', 'sslPassthrough']).to_s
      template        = nested_value(config, ['applicationProfile', 'template']).to_s
      case template
      when 'HTTPS'
        case ssl_passthrough
        when 'true'
          # when template is HTTPS and sslPassthrough is true, persistence=>method is either sourceip or ssl_session_id
          msg = "\n\nWhen sslPassthrough is set to true, persistence => method can only be: sourceip/ssl_session_id\n"
          raise(Puppet::Error, msg) unless %{sourceip ssl_session_id}.include? method
        when 'false'
          # when template is HTTPS and sslPassthrough is false, persistence=>method is either sourceip or cookie
          msg = "\nError: when sslPassthrough is false, persistence => method can only be: sourceip/cookie\n"
          raise(Puppet::Error, msg) unless %{sourceip cookie}.include? method
        end
      when 'HTTP'
        # When template is HTTP, valid persistence method is either sourceip or cookie
        msg = "\nError: when HTTP is set, persistence => method can only be: sourceip/cookie\n"
        raise(Puppet::Error, msg) unless %{sourceip cookie}.include? method
      when 'TCP'
        # When template is TCP, valid persistence method is either sourceip or MSRDP
        msg = "\nError: when TCP is the template, persistence=>method can only be sourceip or cookie\n"
        raise(Puppet::Error, msg) unless %{sourceip msrdp}.include? method
      end
    end
  end

  def flush
    if @flush_required
      config = map.prep_for_serialization config_should
      prep_flush(config)

      if exists?
        id   = config['applicationProfile']['applicationProfileId']
        url  = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/applicationprofiles/#{id}"
        put  url, config
      else
        url  =  "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/applicationprofiles"
        post url, config
      end
    end
  end

  def destroy
    id  = config_is_now['applicationProfile']['applicationProfileId']
    url = "/api/4.0/edges/#{nsx_edge_moref}/loadbalancer/config/applicationprofiles/#{id}"
    delete(url)
  end

  ##### begin misc provider specific methods #####
  # This section is for overrides of automatically-generated property getters and setters. Many
  # providers don't need any overrides. The most common use of overrides is to allow user input
  # of component names instead of object IDs (REST APIs) or Managed Object References (SOAP APIs).

  # using the objectId, find the name
  alias get_application_profile_client_ssl_service_certificate application_profile_client_ssl_service_certificate
  def application_profile_client_ssl_service_certificate
    id     = get_application_profile_client_ssl_service_certificate
    return nil if id.nil?
    result = edge_server_certificates.find{ |x| x['objectId'] == id }
    unless result
      msg = "\nSomething went wrong, the certificate id: '#{id}' was not found\n"
      raise Puppet::Error, msg unless result
    end
    result['name']
  end

  # using the client ssl server certificate name, find the objectId
  alias set_application_profile_client_ssl_service_certificate application_profile_client_ssl_service_certificate=
  def application_profile_client_ssl_service_certificate=(name)
    result = edge_server_certificates.find{|x| x['name'] == name}
    unless result
      # provide a list of available server certificates if the one specified does not exist
      avail_names = edge_server_certificates.collect{|x| x['name']}
      msg         = "\nThe server certificate: '#{name}' was not found, available ones are: #{avail_names}\n"
      raise Puppet::Error, msg unless result
    end
    set_application_profile_client_ssl_service_certificate result['objectId']
  end

  # using the caCertificate objectId, find the name
  alias get_application_profile_client_ssl_ca_certificate application_profile_client_ssl_ca_certificate
  def application_profile_client_ssl_ca_certificate
    id     = get_application_profile_client_ssl_ca_certificate
    return nil if id.nil?
    result = edge_ca_certificates.find{ |x| x['objectId'] == id }
    unless result
      msg = "\nSomething went wrong, the ca certificate id: '#{id}' was not found\n"
      raise Puppet::Error, msg unless result
    end
    result['name']
  end

  # using the name, find the objectId
  alias set_application_profile_client_ssl_ca_certificate application_profile_client_ssl_ca_certificate=
  def application_profile_client_ssl_ca_certificate=(name)
    result = edge_ca_certificates.find{|x| x['name'] == name}
    unless result
      # provide a list of available ca certificates if the one specified does not exist
      avail_names = edge_ca_certificates.collect{|x| x['name']}
      msg         = "\nThe ca certificate: '#{name}' was not found, available ones are: #{avail_names}\n"
      raise Puppet::Error, msg unless result
    end
    set_application_profile_client_ssl_ca_certificate result['objectId']
  end

  # using the caCertificate objectId, find the name
  alias get_application_profile_client_ssl_crl_certificate application_profile_client_ssl_crl_certificate
  def application_profile_client_ssl_crl_certificate
    id     = get_application_profile_client_ssl_crl_certificate
    return nil if id.nil?
    result = edge_crl_certificates.find{ |x| x['objectId'] == id }
    unless result
      msg    = "\nSomething went wrong, the ca certificate id: '#{id}' was not found\n"
      raise Puppet::Error, msg unless result
    end
    result['name']
  end

  # using the name, find the objectId
  alias set_application_profile_client_ssl_crl_certificate application_profile_client_ssl_crl_certificate=
  def application_profile_client_ssl_crl_certificate=(name)
    result = edge_crl_certificates.find{|x| x['name'] == name}
    unless result
      # provide a list of available ca certificates if the one specified does not exist
      avail_names = edge_crl_certificates.collect{|x| x['name']}
      msg         = "\nThe ca certificate: '#{name}' was not found, available ones are: #{avail_names}\n"
      raise Puppet::Error, msg unless result
    end
    set_application_profile_client_ssl_crl_certificate result['objectId']
  end

  # using the server objectId, find the name
  alias get_application_profile_server_ssl_service_certificate application_profile_server_ssl_service_certificate
  def application_profile_server_ssl_service_certificate
    id     = get_application_profile_server_ssl_service_certificate
    return nil if id.nil?
    result = edge_server_certificates.find{ |x| x['objectId'] == id }
    unless result
      msg = "\nSomething went wrong, the certificate id: '#{id}' was not found\n"
      raise Puppet::Error, msg unless result
    end
    result['name']
  end

  # using the server ssl service certificate name, find the objectId
  alias set_application_profile_server_ssl_service_certificate application_profile_server_ssl_service_certificate=
  def application_profile_server_ssl_service_certificate=(name)
    result = edge_server_certificates.find{|x| x['name'] == name}
    unless result
      # provide a list of available server certificates if the one specified does not exist
      avail_names = edge_server_certificates.collect{|x| x['name']}
      msg         = "\nThe server certificate: '#{name}' was not found, available ones are: #{avail_names}\n"
      raise Puppet::Error, msg unless result
    end
    set_application_profile_server_ssl_service_certificate result['objectId']
  end

  # using the caCertificate objectId, find the name
  alias get_application_profile_server_ssl_ca_certificate application_profile_server_ssl_ca_certificate
  def application_profile_server_ssl_ca_certificate
    id     = get_application_profile_server_ssl_ca_certificate
    return nil if id.nil?
    result = edge_ca_certificates.find{ |x| x['objectId'] == id }
    unless result
      msg = "\nSomething went wrong, the ca certificate id: '#{id}' was not found\n"
      raise Puppet::Error, msg unless result
    end
    result['name']
  end

  # using the name, find the objectId
  alias set_application_profile_server_ssl_ca_certificate application_profile_server_ssl_ca_certificate=
  def application_profile_server_ssl_ca_certificate=(name)
    result = edge_ca_certificates.find{|x| x['name'] == name}
    unless result
      # provide a list of available ca certificates if the one specified does not exist
      avail_names = edge_ca_certificates.collect{|x| x['name']}
      msg         = "\nThe ca certificate: '#{name}' was not found, available ones are: #{avail_names}\n"
      raise Puppet::Error, msg unless result
    end
    set_application_profile_server_ssl_ca_certificate result['objectId']
  end

  # using the caCertificate objectId, find the name
  alias get_application_profile_server_ssl_crl_certificate application_profile_server_ssl_crl_certificate
  def application_profile_server_ssl_crl_certificate
    id     = get_application_profile_server_ssl_crl_certificate
    return nil if id.nil?
    result = edge_crl_certificates.find{ |x| x['objectId'] == id }
    unless result
      msg = "\nSomething went wrong, the ca certificate id: '#{id}' was not found\n"
      raise Puppet::Error, msg unless result
    end
    result['name']
  end

  # using the name, find the objectId
  alias set_application_profile_server_ssl_crl_certificate application_profile_server_ssl_crl_certificate=
  def application_profile_server_ssl_crl_certificate=(name)
    result = edge_crl_certificates.find{|x| x['name'] == name}
    unless result
      # provide a list of available ca certificates if the one specified does not exist
      avail_names = edge_crl_certificates.collect{|x| x['name']}
      msg         = "\nThe ca certificate: '#{name}' was not found, available ones are: #{avail_names}\n"
      raise Puppet::Error, msg unless result
    end
    set_application_profile_server_ssl_crl_certificate result['objectId']
  end

  ##### begin private provider specific methods section #####
  # These methods are provider specific and that can be private
  private

  def edge_certificates
    @edge_certificates ||=
      begin
        url = "/api/2.0/services/truststore/certificate/scope/#{nsx_edge_moref}"
        ensure_array( nested_value(get(url), [ 'certificates', 'certificate' ]) )
      end
  end

  def edge_server_certificates
    @edge_server_certificates ||=
      begin
        server_certs = []
        edge_certificates.each do |cert|
          case cert['x509Certificate']
          when Array
            server_certs << cert
          when Hash
            if cert['x509Certificate']['isCa'] == false
              server_certs << cert
            end
          end
        end
        server_certs
      end
  end

  def edge_ca_certificates
    @edge_ca_certificates ||=
      begin
        ca_certs = []
        edge_certificates.each do |cert|
          case cert['x509Certificate']
          when Array
            ca_certs << cert
          when Hash
            if cert['x509Certificate']['isCa'] == true
              ca_certs << cert
            end
          end
        end
        ca_certs
        #ensure_array( edge_certificates.find_all{ |x| x['x509Certificate']['isCa'] == true } )
      end
  end

  def edge_crl_certificates
    @edge_crl_certificates ||=
      begin
        url = "/api/2.0/services/truststore/crl/scope/#{nsx_edge_moref}"
        ensure_array( nested_value(get(url), [ 'crls', 'crl' ]) )
      end
  end

end
