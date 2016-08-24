# Copyright (C) 2014-2016 VMware, Inc.

require 'set'

module PuppetX::VMware::MapperNsx

  class NsxEdgeLbAppRule < Map
    def initialize
      @initTree = {
        :applicationRule => {
          Node => NodeData[
            :node_type => 'REST',
            :olio => {
              :ensure_is_class => ::Hash,
            },
            #:xml_ns    => 'http://www.vmware.com/vcloud/v1.5',
            #:xml_type  => 'application/vnd.vmware.admin.organization+xml',
          ],
          :applicationRuleId => LeafData[
            :desc => "should not be specified in the manifest, used internally",
          ],
          :'name' => LeafData[
            :prop_name => 'name',
          ],
          :script => LeafData[
            :desc => "custom script",
          ],
        }, # end :applicationRule
      }
      super
    end
  end
end

