# Copyright (C) 2014-2016 VMware, Inc.
import 'data.pp'

transport { 'nsx':
  username => $nsx['username'],
  password => $nsx['password'],
  server   => $nsx['server'],
}

transport { 'vcenter':
  username => $vcenter['username'],
  password => $vcenter['password'],
  server   => $vcenter['server'],
  options  => $vcenter['options'],
}

nsx_ha { $edge['name']:
  ip_addresses    => $edge['ha']['ip_addresses'],
  enabled         => 'true',
  logging         => { 'enable' => true, 'logLevel' => 'error' },
  vnic            => $edge['ha']['vnic'],
  datastore_name  => $edge['ha']['datastore_name'],
  datacenter_name => $dc1['name'],
  transport       => Transport['nsx'],
  require         => [ Transport['nsx'], Transport['vcenter'] ]
}
