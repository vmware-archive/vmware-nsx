# Copyright (C) 2014-2016 VMware, Inc.

Puppet::Type.newtype(:nsx_component) do
  @doc = 'Manage NSX components, these are the services used by NSX'

  ensurable do
    desc <<-EOT
    Valid ensure values are "running" and "stopped" (present/enabled and absent/disabled will also
    map to their respective values)
    EOT
    newvalue(:present) do
      provider.start
    end
    newvalue(:absent) do
      provider.stop
    end

    aliasvalue(:running, :present)
    aliasvalue(:enabled, :present)
    aliasvalue(:stopped, :absent)
    aliasvalue(:disabled, :absent)

    defaultto(:present)
  end

  newparam(:component, :namevar => true ) do
    desc 'Component ID'
  end

  newparam(:poll_interval) do
    desc 'Wait time, in seconds, between polling service status attempts'
    newvalues(/^\d+$/)

    munge do |value|
      value.to_i
    end

    defaultto(10)
  end

  newparam(:timeout) do
    desc 'Maximum time, in seconds, to wait for service status change to complete'
    newvalues(/^\d+$/)

    munge do |value|
      value.to_i
    end

    defaultto(240)
  end

end
