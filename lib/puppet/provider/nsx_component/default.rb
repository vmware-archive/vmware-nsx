# Copyright (C) 2014-2016 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'nsx')

Puppet::Type.type(:nsx_component).provide(
  :default,
  :parent => Puppet::Provider::Nsx
) do
  @doc = 'Manage NSX components, these are the services used by NSX'

  def start
    set_status('start') unless get_status == 'STARTING'
    status_loop('RUNNING')
    Puppet.debug("#{resource[:name]} service started successfully")
  end

  def stop
    set_status('stop')
    status_loop('STOPPED')
    Puppet.debug("#{resource[:name]} stopped successfully")
  end

  def exists?
    get_status == 'RUNNING'
  end

  def status_loop(target_status)
    start_time = Time.now
    begin
      if Time.now - start_time > resource[:timeout]
        raise Puppet::Error,
          "#{resource[:timeout]} second timeout exceeded while waiting on #{resource[:component]} service to be #{target_status.upcase}.}"
      end
      sleep resource[:poll_interval]
      status = get_status
    end until status == target_status
  end

  def get_status
    Puppet.debug("Getting #{resource[:component]} service status.")
    status = get("api/1.0/appliance-management/components/component/#{resource[:component]}/status")['result']['result']
    Puppet.debug("#{resource[:component]} service status is #{status}")
    status
  end

  def set_status(status)
    Puppet.debug("Setting #{resource[:component]} service status.")
    post("api/1.0/appliance-management/components/component/#{resource[:component]}/toggleStatus/#{status}", {})
  end
end
