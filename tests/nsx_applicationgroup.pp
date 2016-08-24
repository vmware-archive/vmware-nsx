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

Nsx_application_group {
  transport                => Transport['nsx'],
}

nsx_application_group { 'puppet_and_smtp':
     ensure               => present,
     application_member       => [ 'puppet', 'SMTP' ],
     #application_group_member => [ 'another_application_group' ], # if applicable
     scope_type               => 'edge',
     scope_name               => $edge['name'],
}
