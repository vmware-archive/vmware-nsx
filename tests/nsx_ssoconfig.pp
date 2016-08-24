# Copyright (C) 2014-2016 VMware, Inc.
import 'data.pp'

transport { 'nsx':
  username => $nsx['username'],
  password => $nsx['password'],
  server   => $nsx['server'],
}

nsx_ssoconfig { 'configure_sso' :
  ensure                 => present,
  sso_lookup_service_url => $sso_url,
  sso_admin_username     => $sso_user,
  sso_admin_userpassword => $sso_password,
  transport              => Transport['nsx']
}
