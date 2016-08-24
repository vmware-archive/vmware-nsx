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

Nsx_ipset {
  transport => Transport['nsx'],
}

vc_datacenter { $dc1['name']:
  ensure    => present,
  path      => $dc1['path'],
  transport => Transport['vcenter'],
}

nsx_ipset { 'demo':
  ensure     => present,
  value      => [ '10.10.10.1', '10.1.1.1', '10.1.1.2' ],
  scope_name => $dc1['name'],
  scope_type => 'datacenter',
}

nsx_ipset { 'demo2':
  ensure     => present,
  value      => [ '10.10.10.1' ],
  scope_name => $edge['name'],
  scope_type => 'edge',
}

nsx_ipset { 'demo3':
  ensure     => present,
  value      => [ '10.10.10.1' ],
  scope_name => 'global',
  scope_type => 'global',
}
