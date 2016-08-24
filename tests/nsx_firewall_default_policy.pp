# Copyright (C) 2014-2016 VMware, Inc.
import 'data.pp'

transport { 'nsx':
  username => $nsx['username'],
  password => $nsx['password'],
  server   => $nsx['server'],
}

nsx_firewall_default_policy { $edge['name']:
  action             => 'accept',
  logging_enabled    => false,
  transport          => Transport['nsx'],
}
