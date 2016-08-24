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

nsx::edge_lb_app_rule { $lb_app_rule1['name']:
  ensure     => present,
  scope_name => $edge['name'],
  spec       => $lb_app_rule1['spec'],
  transport  => Transport['nsx'],
}->

nsx::edge_lb_monitor { $lb_monitor1['name']:
  ensure     => present,
  scope_name => $edge['name'],
  spec       => $lb_monitor1['spec'],
  transport  => Transport['nsx'],
}->

nsx::edge_lb_pool { $lb_pool1['name']:
  ensure     => present,
  scope_name => $edge['name'],
  spec       => $lb_pool1['spec'],
  transport  => Transport['nsx'],
}->

nsx::edge_lb_pool { $lb_pool2['name']:
  ensure          => present,
  scope_name      => $edge['name'],
  datacenter_name => $dc1['name'],
  spec            => $lb_pool2['spec'],
  transport       => Transport['nsx'],
}

nsx::edge_lb_app_profile { $lb_app_prof1['name']:
  ensure     => present,
  scope_name => $edge['name'],
  spec       => $lb_app_prof1['spec'],
  transport  => Transport['nsx'],
}->

nsx::edge_lb_vip { $lb_vip1['name']:
  ensure     => present,
  scope_name => $edge['name'],
  spec       => $lb_vip1['spec'],
  transport  => Transport['nsx'],
}
