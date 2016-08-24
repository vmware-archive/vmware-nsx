# Copyright (C) 2014-2016 VMware, Inc.

require 'set'

module PuppetX::VMware::MapperNsx

  class NsxEdgeLbAppProfile < Map
    def initialize
      @initTree = {
        :applicationProfile => {
          Node => NodeData[
            :node_type => 'REST',
            :olio => {
              :ensure_is_class => ::Hash,
            },
            #:xml_ns    => 'http://www.vmware.com/vcloud/v1.5',
            #:xml_type  => 'application/vnd.vmware.admin.organization+xml',
          ],
          :applicationProfileId => LeafData[
          ],
          :'name' => LeafData[
            :prop_name => 'name',
          ],
          :template => LeafData[
            :desc => "Whether or not ssl is enabled",
            :valid_enum => [:TCP, :HTTP, :HTTPS],
          ],
          :serverSslEnabled => LeafData[
            :desc => "Whether or not Pool Side ssl is enabled",
            :valid_enum => [:true, :false],
          ],
          :insertXForwardedFor => LeafData[
            :desc => "Whether or not XforwardedFor header is inserted",
            :valid_enum => [:true, :false],
          ],
          :sslPassthrough => LeafData[
            :desc => "Whether or not sslpassthrough is enabled",
            :valid_enum => [:true, :false],
          ],
          :httpRedirect => {
            Node => NodeData[
              :node_type => 'REST',
            ],
            :to => LeafData[
              :desc => "Redirect uri",
              :olio => {
                :ensure_is_class => ::String,
              },
            ],
          },
          # optional
          :clientSsl => {
            Node => NodeData[
              :node_type => 'REST',
            ],
            :clientAuth => LeafData[
              :desc => "clientAuth Settings, valid values are: ignore/required",
              :olio => {
                :ensure_is_class => ::String,
              },
              :valid_enum => [:ignore, :required],
            ],
            :ciphers => LeafData[
              :desc => "Redirect uri",
              :olio => {
                :ensure_is_class => ::String,
              },
            ],
            :serviceCertificate => LeafData[
              :desc => "this is the common name of the certificate that was uploaded",
              :olio => {
                :ensure_is_class => ::String,
              },
            ],
            :caCertificate => LeafData[
              :desc => "caCertificate",
              :olio => {
                :ensure_is_class => ::Array,
              },
            ],
            :crlCertificate => LeafData[
              :desc => "crlCertificate",
              :olio => {
                :ensure_is_class => ::Array,
              },
            ],
          },
          # optional
          :serverSsl => {
            Node => NodeData[
              :node_type => 'REST',
            ],
            :ciphers => LeafData[
              :desc => "Redirect uri",
              :olio => {
                :ensure_is_class => ::String,
              },
            ],
            :serviceCertificate => LeafData[
              :desc => "this is the common name of the certificate that was uploaded",
              :olio => {
                :ensure_is_class => ::String,
              },
            ],
            :caCertificate => LeafData[
              :desc => "caCertificate",
              :olio => {
                :ensure_is_class => ::Array,
              },
            ],
            :crlCertificate => LeafData[
              :desc => "crlCertificate",
              :olio => {
                :ensure_is_class => ::Array,
              },
            ],
          },
          :persistence => {
            Node => NodeData[
              :node_type => 'REST',
            ],
            :method => LeafData[
              :desc => "persistence method, possible values are: cookie/ssl_sessionid/sourceip/msrdp",
              :valid_enum => [:cookie, :ssl_sessionid, :sourceip, :msrdp],
            ],
            :cookieName => LeafData[
              :desc => "name of the cookie inserted",
              :olio => {
                :ensure_is_class => ::String,
              },
              :requires_siblings=> [
                :method,
                :cookieMode,
              ],
            ],
            :cookieMode => LeafData[
              :desc => "cookie mode, valid modes are: insert/prefix/app",
              :valid_enum => [:insert, :prefix, :app ],
              :requires_siblings => [
                :cookieName,
                :method,
              ],
            ],
          },
        },
      }
      super
    end
  end
end

