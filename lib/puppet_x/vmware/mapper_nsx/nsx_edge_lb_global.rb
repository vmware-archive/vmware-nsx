# Copyright (C) 2014-2016 VMware, Inc.

require 'set'

module PuppetX::VMware::MapperNsx

  class NsxEdgeLbGlobal < Map
    def initialize
      @initTree = {
        :loadBalancer => {
          Node => NodeData[
            :node_type => 'REST',
            :olio => {
              :ensure_is_class => ::Hash,
            },
            #:xml_ns    => 'http://www.vmware.com/vcloud/v1.5',
            #:xml_type  => 'application/vnd.vmware.admin.organization+xml',
          ],
          :enabled => LeafData[
            :desc => "type of monitor http/https/tcp",
            :valid_enum => [:true, :false],
          ],
          :enableServiceInsertion => LeafData[
            :desc => "type of monitor http/https/tcp",
            :valid_enum => [:true, :false],
          ],
          :accelerationEnabled => LeafData[
            :desc => "type of monitor http/https/tcp",
            :valid_enum => [:true, :false],
          ],
          :logging => {
            Node => NodeData[
              :node_type => 'REST',
              :olio => {
                :ensure_is_class => ::Hash,
              },
            ],
            :enable => LeafData[
              :desc => "If logging is enabled",
              :valid_enum => [:true, :false],
            ],
            :logLevel => LeafData[
              :desc => "logging level",
              :valid_enum => [:emergency, :alert, :critical, :error, :warning, :notice, :info, :debug],
            ],
          }, # end :logging
          :pool => {
            Node => NodeData[
              :node_type => 'REST',
            ],
          },
          :applicationProfile => {
            Node => NodeData[
              :node_type => 'REST',
            ],
          },
          :monitor => {
            Node => NodeData[
              :node_type => 'REST',
            ],
          },
          :virtualServer => {
            Node => NodeData[
              :node_type => 'REST',
            ],
          },
          :applicationRule => {
            Node => NodeData[
              :node_type => 'REST',
            ],
          },
          :version => LeafData[
            :desc => "version number of the configuration",
            :olio => {
              :ensure_is_class => ::Integer,
            },
          ],
        }, # end :loadBalancer
      }
      super
    end
  end
end

