# Copyright 2013, 2014 VMware, Inc.

require 'set'

module PuppetX::VMware::MapperNsx

  class NsxEdgeLbMonitor < Map
    def initialize
      @initTree = {
        :monitor => {
          Node => NodeData[
            :node_type => 'REST',
            :olio => {
              :ensure_is_class => ::Hash,
            },
            #:xml_ns    => 'http://www.vmware.com/vcloud/v1.5',
            #:xml_type  => 'application/vnd.vmware.admin.organization+xml',
          ],
          :monitorId => LeafData[
            :desc => "Only used internally when a update or removal to an existing monitor",
          ],
          :type => LeafData[
            :desc => "type of monitor http/https/tcp",
            :valid_enum => [:http, :https, :tcp],
          ],
          :interval => LeafData[
            :desc => "interval to check in seconds",
            :olio => {
              :ensure_is_class => ::Integer,
            },
          ],
          :timeout => LeafData[
            :desc => "timeout in seconds",
            :olio => {
              :ensure_is_class => ::Integer,
            },
          ],
          :maxRetries => LeafData[
            :desc => "max retries",
            :olio => {
              :ensure_is_class => ::Integer,
            },
          ],
          :method => LeafData[
            :desc => "monitor method GET/OPTIONS/POST",
            :valid_enum => [:GET, :OPTIONS, :POST],
          ],
          :url => LeafData[
            :desc => "url to use, default is *",
            :olio => {
              :ensure_is_class => ::String,
            },
          ],
          :'name' => LeafData[
            :prop_name => 'name',
          ],
        }, # end :monitor
      }
      super
    end
  end
end

