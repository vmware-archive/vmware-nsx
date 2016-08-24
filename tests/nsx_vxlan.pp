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

nsx_vxlan_switch { "${vxlan_switch1['switch']['name']}":
  switch            => $vxlan_switch1['switch'],
  teaming           => $vxlan_switch1['teaming'],
  mtu               => $vxlan_switch1['mtu'],
  datacenter_name   => $dc1['name'],
  transport         => Transport['nsx'],
}

nsx_vxlan_map { $vxlan_map1['vlan_id']:
  switch          => $vxlan_map1['switch'],
  vlan_id         => $vxlan_map1['vlan_id'],
  datacenter_name => $dc1['name'],
  cluster_name    => $cluster1['name'],
  require         => Nsx_vxlan_switch["${vxlan_switch1[switch][name]}"],
  transport       => Transport['nsx'],
}

nsx_vxlan_segment { $vxlan_segment1['name']:
  id        => $vxlan_segment1['id'],
  name      => $vxlan_segment1['name'],
  desc      => $vxlan_segment1['desc'],
  begin     => $vxlan_segment1['begin'],
  end       => $vxlan_segment1['end'],
  require   => Nsx_vxlan_map["${vxlan_map1[vlan_id]}"],
  transport => Transport['nsx'],
}

nsx_vxlan_multicast { $vxlan_multicast1['name']:
  id        => $vxlan_multicast1['id'],
  name      => $vxlan_multicast1['name'],
  desc      => $vxlan_multicast1['desc'],
  begin     => $vxlan_multicast1['begin'],
  end       => $vxlan_multicast1['end'],
  require   => Nsx_vxlan_segment["${vxlan_segment1[name]}"],
  transport => Transport['nsx'],
}

nsx_vxlan_scope { $vxlan_scope1['name']:
  name            => $vxlan_scope1['name'],
  clusters        => $vxlan_scope1['clusters'],
  datacenter_name => $dc1['name'],
  cluster_name    => $cluster1['name'],
  require         => Nsx_vxlan_multicast["${vxlan_multicast1[name]}"],
  transport       => Transport['nsx'],
}

nsx_vxlan { $vxlan1['name']:
  name        => $vxlan1['name'],
  description => $vxlan1['description'],
  tenant_id   => $vxlan1['tenant_id'],
  require     => Nsx_vxlan_scope["${vxlan_scope1[name]}"],
  transport   => Transport['nsx'],
}

nsx_vxlan_udp { $nsx['server']:
  vxlan_udp_port  => $vxlan_udp_port,
  require         => Nsx_vxlan["${vxlan1[name]}"],
  transport       => Transport['nsx'],
}
