

# vmware-nsx

## Overview

This module uses rest client to interact with the NSX API.

## Installation

$ puppet module install vmware/nsx

## Documentation

This module uses Puppet Transport resources like our other modules, such as [vmware-vcenter](https://github.com/vmware/vmware-vcenter). The trasnport resource stores the conenction information for the rest client.

    # The name of the transport is referenced by other resource:
    transport { 'nsx':
      username => 'admin',
      password => 'vmware',
      server   => 'nsx.local',
    }

All NSX resources use the transport metaparameter to specify the NSX Manager where the resource exists.

   nsx_ssoconfig { \"config_sso\":
     ensure                        => present,
     sso_lookup_service_url        => $sso_url,
     sso_admin_username            => $sso_username,
     sso_admin_userpassword        => $sso_password,
     sso_lookup_service_thumbprint => $sso_thumbprint,
     transport                     => Transport["nsx"],
   }

See tests folder for additional examples.

## Contributing

The vmware-nsx project team welcomes contributions from the community. If you wish to contribute code and you have not
signed our contributor license agreement (CLA), our bot will update the issue when you open a Pull Request. For any
questions about the CLA process, please refer to our [FAQ](https://cla.vmware.com/faq). For more detailed information,
refer to [CONTRIBUTING.md](CONTRIBUTING.md).

## License
Copyright (C) 2016 VMware, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and

