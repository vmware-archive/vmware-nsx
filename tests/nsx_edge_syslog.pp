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

nsx_edge_syslog { $edge['name']:
  server_addresses => [ '10.0.0.1', '10.0.0.2' ],
  protocol         => 'udp',
  enabled          => true,
  transport        => Transport['nsx'],
}
