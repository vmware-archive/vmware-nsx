# Copyright (C) 2014 VMware, Inc.
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

Nsx_application {
  transport            => Transport['nsx'],
}

nsx_application { 'puppet':
  ensure               => present,
  application_protocol => 'TCP',
  value                => [ '8140' ],
  scope_type           => 'edge',
  scope_name           => $edge['name'],
}

nsx_application { 'tcp-5670':
  ensure               => present,
  application_protocol => 'TCP',
  value                => [ '5670' ],
  scope_type           => 'edge',
  scope_name           => $edge['name'],
}

nsx_application { 'global-tcp-5672':
  ensure               => present,
  application_protocol => 'TCP',
  value                => [ '5672' ],
  scope_type           => 'global',
  scope_name           => 'global',
}
