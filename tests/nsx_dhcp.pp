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

vc_datacenter { $dc1['name']:
  ensure    => present,
  path      => $dc1['path'],
  transport => Transport['vcenter'],
}

nsx_dhcp { $edge['name']:
  datacenter_name => $dc1['name'],
  dhcp_pools      => $dhcp_pools,
  dhcp_bindings   => $dhcp_bindings,
  dhcp_logging    => $dhcp_logging,
  dhcp_enabled    => $dhcp_enabled,
  transport       => Transport['nsx'],
}