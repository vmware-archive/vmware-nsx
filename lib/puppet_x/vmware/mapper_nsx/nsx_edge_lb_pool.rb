# Copyright 2013, 2014 VMware, Inc.

require 'set'

module PuppetX::VMware::MapperNsx

  class NsxEdgeLbPool < Map
    def initialize
      @initTree = {
        :pool => {
          Node => NodeData[
            :node_type => 'REST',
            :olio => {
              :ensure_is_class => ::Hash,
            },
            #:xml_ns    => 'http://www.vmware.com/vcloud/v1.5',
            #:xml_type  => 'application/vnd.vmware.admin.organization+xml',
          ],
          :poolId => LeafData[
            :desc => "Only used internally when a update or removal to an existing pool",
          ],
          :'name' => LeafData[
            :prop_name => 'name',
          ],
          :description => LeafData[
            :desc => "Description",
            :olio => {
              :ensure_is_class => ::String,
            },
          ],
          :algorithm => LeafData[
            :desc => "algorithm, valid values: round-robin/ip-hash/uri/leastconn",
            :valid_enum => [ :'round-robin', :'ip-hash', :uri, :leastconn, ],
          ],
          :transparent => LeafData[
            :desc => "Whether or not transparent is set to true/false",
            :valid_enum => [:true, :false],
          ],
          :monitorId => LeafData[
            :desc => "Optional: which monitor name to use, the built-in ones are: default_(tcp|http|https)_monitor",
          ],
          :applicationRuleId => LeafData[
            :desc => "Optional: an application rule",
          ],
          # optional
          :member => LeafData[
            :olio => {
              Puppet::Property::VMware_Array_Hash => {
                :property_option => {
                  :array_matching => :all,
                  #:inclusive      => :false,
                  #:preserve       => :true,
                },
              }, 
            },
          ], # end :member
        }, # end :pool
      }
      super
    end
  end
end

