# Copyright (C) 2014-2016 VMware, Inc.

require 'set'

module PuppetX::VMware::MapperNsx

  class NsxEdgeLbVip < Map
    def initialize
      @initTree = {
        :virtualServer => {
          Node => NodeData[
            :node_type => 'REST',
            :olio => {
              :ensure_is_class => ::Hash,
            },
            #:xml_ns    => 'http://www.vmware.com/vcloud/v1.5',
            #:xml_type  => 'application/vnd.vmware.admin.organization+xml',
          ],
          :virtualServerId => LeafData[
          ],
          :'name' => LeafData[
            :prop_name => 'name',
          ],
          :description => LeafData[
            :desc => "description of the vip",
          ],
          :enabled => LeafData[
            :desc => "Whether or not vip is enabled",
            :valid_enum => [:true, :false],
          ],
          :ipAddress => LeafData[
            :desc => "ip address of the vip",
          ],
          :protocol => LeafData[
            :desc => "protocol of the vip",
          ],
          :port => LeafData[
            :desc => "port of the vip",
            :olio => {
              :ensure_is_class => ::Integer,
            },
          ],
          :connectionLimit => LeafData[
            :desc => "Connection Limit of the vip",
            :olio => {
              :ensure_is_class => ::Integer,
            },
          ],
          :connectionRateLimit => LeafData[
            :desc => "connection Rate Limit of the vip",
            :olio => {
              :ensure_is_class => ::Integer,
            },
          ],
          :applicationProfileId => LeafData[
            :desc => "application profile the vip uses, this should be the name which will automatically get converted into an id",
            :olio => {
              :ensure_is_class => ::String,
            },
          ],
          :applicationRuleId => LeafData[
            :desc => "application rule Id the vip uses, this should be the name which will automatically get converted into an id",
            :olio => {
              :ensure_is_class => ::String,
            },
          ],
          :defaultPoolId => LeafData[
            :desc => "default pool the vip uses, this should be the name which will automatically get converted into an id",
            :olio => {
              :ensure_is_class => ::String,
            },
          ],
          :enableServiceInsertion => LeafData[
            :desc => "Whether or not service insertion is enabled on the vip uses",
            :valid_enum => [:true, :false],
          ],
          :accelerationEnabled => LeafData[
            :desc => "Whether or not acceleration is enabled on the vip",
            :valid_enum => [:true, :false],
          ],
        },
      }
      super
    end
  end
end

