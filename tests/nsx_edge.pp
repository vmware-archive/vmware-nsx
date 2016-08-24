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

vc_datacenter { $dc1['name']:
  ensure    => present,
  path      => $dc1['path'],
  transport => Transport['vcenter'],
}

nsx_edge { "${nsx['server']}:${edge['name']}":
  ensure             => present,
  datacenter_name    => $dc1['name'],
  resource_pool_name => $cluster1['name'],
  enable_aesni       => false,
  enable_fips        => false,
  enable_tcp_loose   => false,
  vse_log_level      => 'info',
  fqdn               => $edge['fqdn'],
  vnics              => $edge['vnics'],
  cli_settings       => $edge['cli_settings'],
  upgrade            => true,
  transport  => Transport['nsx'],
}
