# Copyright 2013, 2014 VMware, Inc.
require 'pathname' # WORK_AROUND #14073 and #7788

vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet_x/vmware/util'

module_lib = Pathname.new(__FILE__).parent.parent.parent

require 'set'

  module PuppetX
    module VMware
      module MapperNsx

      # constant for a meaningful unique name that you don't have to invent
      PROP_NAME_IS_FULL_PATH = :PROP_NAME_IS_FULL_PATH

      # constants for use in Leaf Nodes for InheritablePolicy
      InheritablePolicyInherited = :InheritablePolicyInherited
      InheritablePolicyExempt = :InheritablePolicyExempt
      InheritablePolicyValue = :InheritablePolicyValue

      def self.new_map mapname
        mapfile = PuppetX::VMware::Util.snakeize mapname
        require 'pathname'
        file_path = Pathname.new(__FILE__)
        Puppet.debug "require \"#{file_path.parent}/#{file_path.basename '.rb'}/#{mapfile}\""
        require "#{file_path.parent}/#{file_path.basename '.rb'}/#{mapfile}"
        const_get(mapname).new
      rescue Exception => e
        fail "#{self.name}: Error accessing or creating mapper \"#{mapname}\": #{e.message}"
      end

      class MapComponent

        def initialize(input, prop_names)
          # copy input to @props hash
          @props = {}
          input = input.dup
          prop_names.each do |name|
            if input.include? name
              v = input.delete name
              @props[name] =
                  if v.respond_to?(:dup)
                    begin
                      v.dup
                    rescue TypeError
                      # several classes claim to respond_to?(:dup)
                      # but they actually throw a TypeError
                      v
                    end
                  else
                    v
                  end
            end
          end
          unless input.empty?
            fail "#{self.class} doesn't recognize some input: #{input.inspect}"
          end
        end

        private

        def self.property_access prop_names=[]
          define_method(:copy_props) { @props.dup }
          prop_names.each do |name|
            define_method(name) { @props[name] }
          end
          if prop_names.include? :path_should
            define_method(:camel_name) { @props[:path_should][-1] }
            define_method(:full_name) { @props[:path_should].join('.').gsub(/@/, '') }
          end
        end
      end

      class Leaf < MapComponent
        Prop_names = [
            :desc,
            :misc,
            :munge,
            :olio,
            :path_is_now,
            :path_should,
            :prop_name,
            :requires,
            :requires_siblings,
            :validate,
            :valid_enum,
          ]

        def initialize input
          # copy input to @props hash
          super input, Prop_names

          # check for required values
          fail "#{self.class} doesn't include 'path_should'" unless
            @props[:path_should]
          @props[:misc] ||= []
          @props[:olio] ||= {}
          @props[:requires] ||= []
          @props[:requires_siblings] ||= []

          # set defaults and munge
          @props[:path_is_now] ||= @props[:path_should]
            # .dup not necessary because of following map to_sym
          @props[:path_is_now] = @props[:path_is_now].map{|v| v.to_s}
          @props[:path_should] = @props[:path_should].map{|v| v.to_s}
          @props[:prop_name] =
            case @props[:prop_name]
            when nil, PROP_NAME_IS_FULL_PATH
              # autogenerate using full path
              x = @props[:path_should].
                  map{|name| PuppetX::VMware::Util.snakeize name}.
                  join "_"
              x = x.to_sym
            else
              # specified explicitly in map
              @props[:prop_name]
            end
          # gyoku expects '@' prefix on keys to indicate xml attributes
          # but puppet and ruby don't like '@' signs in method identifiers
          @props[:prop_name] = @props[:prop_name].to_s.gsub(/@/, '').to_sym
        end

        self.property_access Prop_names
      end

      class Node < MapComponent
        Prop_names = [
            :misc,
            :node_type,
            :node_types,
            :node_type_key,
            :olio,
            :path_should,
            :path_is_now,
            :url,
            :xml_attr,
            :xml_order,
            :xml_ns,
            :xml_type,
          ]

        def initialize input
          # copy input to @props hash
          super input, Prop_names

          # check for required values
          fail "#{self.class} doesn't include 'node_type'" unless
            @props[:node_type]
          @props[:misc]      ||= Set.new()
          @props[:olio]      ||= {}
          @props[:xml_order] ||= []
          @props[:xml_attr]  ||= []
          @props[:xml_type]  ||= ""
          @props[:xml_ns]    ||= ""
          # xml_type and xml_ns required on first node
          # will be checked when node_list is created
          
          # set defaults and munge
          @props[:path_is_now] ||= @props[:path_should]
            # .dup not necessary because of following map to_sym
          @props[:path_is_now] = @props[:path_is_now].map{|v| v.to_s}
          @props[:path_should] = @props[:path_should].map{|v| v.to_s}

          @props[:node_type_key] ||= :vsphereType if
            @props[:node_type] == :ABSTRACT
        end

        def path_is_now_to_type
          self.path_is_now.dup << self.node_type_key
        end

        self.property_access Prop_names
      end

      # in effect, these are labels for distinguishing hash
      # values that specify Leaf or Node initialization from
      # hash values that may be roots of trees
      class LeafData < Hash
      end
      class NodeData < Hash
      end

      class Map
        # abstract class 
        # - concrete classes contain initialization data
        # - this class contains methods
        #
        def initialize
          # @initTree is defined in subclasses...
          @leaf_list = []
          @node_list = []

          # walk down the initTree and find the leaves
          walk_down @initTree, [], @leaf_list, @node_list

          # now that it's complete, go through leaf_list 
          # to resolve interdependencies
          requires_for_inheritable_policy
          requires_for_requires_siblings

        end

        attr_reader :leaf_list, :node_list

        def nested_value *args, &block
          PuppetX::VMware::Util.nested_value *args, &block
        end
        def nested_value_set *args
          PuppetX::VMware::Util.nested_value_set *args, transform_keys=false
        end

        def gyoku_issue_48 cfg, node
          return unless node.misc.include? :gyoku_issue_48
          self_closing = node.misc.include? :self_closing
          # full keypaths
          k_target     = node.path_should
          k_parent     = node.path_should[0..-2]
          # relative key to target from parent
          r_target     = k_target[-1]
          #
          parent = nested_value cfg, k_parent
          parent[r_target].each{|tel|
            attribute_keys = node.xml_attr
            unless attribute_keys.empty?
              gsk = :'attributes!'
              parent[gsk]           ||= {}
              parent[gsk][r_target] ||= []
              parent[gsk][r_target] <<
                # attribute keys have '@' prefix except in :attributes! 
                # hash, so keys are changed as values are transferred
                attribute_keys.reduce({}){|h, ak| h[ak[1..-1]] = tel.delete ak; h}
            end
          }
          parent[r_target] = Array.new(parent.delete(r_target).size, '') if self_closing
        end

        def gyoku_self_closing_keys cfg, node
          return unless node.misc.include? :self_closing
          key_parent = node.path_should[0..-2]
          if parent = nested_value(cfg, key_parent)
            old_rel = node.path_should[-1]
            new_rel = old_rel + '/'
            new_abs = key_parent + [new_rel]
            # move content from old to new key in parent
            if (parent.include? old_rel)
              nested_value_set cfg, new_abs, (parent.delete old_rel)
            end
            # fixup :order!
            if parent.include? :order!
              o = parent[:order!]
              i = o.index old_rel
              o[i] = new_rel if i
            end
            # fixup :attributes!
            if parent.include? :attributes!
              a = parent[:attributes!]
              if a.include? old_rel
                # move value from old key to new key
                a[new_rel] = a.delete old_rel
              end
            end
          end
        end

        def prep_for_serialization should
          cfg = Marshal.load(Marshal.dump(should))
          # Step through the node list, which is in bottom-up sequence.
          @node_list.each do |node|
            # for vcd api - add order of enclosed elements
            # for gyoku   - use pseudo-element key :order!
            unless node.xml_order.empty?
              container = nested_value cfg, node.path_should
              if container
                keys_in_use = container.keys
                order = node.xml_order.select{|e| keys_in_use.include? e}
                p = node.path_should + [:'order!']
                nested_value_set cfg, p, order
              end
            end
            # for vcd api - add type
            # for gyoku   - prefix '@' to flag as attribute
            unless node.xml_type == ""
              p = node.path_should + ['@type']
              nested_value_set cfg, p, node.xml_type
            end
            # for vcd api - add xmlns
            # for gyoku   - prefix '@' to flag as attribute
            unless node.xml_ns == ""
              p = node.path_should + ['@xmlns']
              nested_value_set cfg, p, node.xml_ns
            end
            # for vcd api - delete 'Link' elements
            node_ref = nested_value(cfg, node.path_should)
            node_ref.delete 'Link' if node_ref
            # for vcd api - delete a key if it is empty and we dont want to send
            if node.misc.include? :del_if_empty
              parent = nested_value(cfg,node.path_should[0..-2])
              child  = nested_value(cfg,node.path_should)
              parent.delete(node.path_should[-1]) if child and child.empty?
            end
            # for gyoku   - https://github.com/savonrb/gyoku/issues/48
            # *** MOVES CONTENT AWAY FROM PATH_SHOULD ***
            gyoku_issue_48 cfg, node
          end
          @node_list.each do |node|
            # for gyoku   - mark self-closing elements
            # *** MOVES CONTENT AWAY FROM PATH_SHOULD ***
            # This changes sibling values, and is delayed
            # until a second pass through node_list so that
            # all siblings will have been created.
            # - :order! => [..., mykey, ...]     : 
            #   created when parent node is processed by
            #   prep_for_serialization (see xml_order)
            # - :attributes! => { ..., mykey => {}, ...}
            #   created when this node is processed by
            #   prep_for_serialization (gyoku_issue_48)
            gyoku_self_closing_keys cfg, node
          end
          cfg
        end
        alias objectify prep_for_serialization

        def ensure_is_class cfg, keypath, klass
        end

        PIN_NO_PARENT = :'!parent'
        PIN_NO_VALUE  = :'!value'
        PIN_NIL_VALUE = :'!nil'

        def prep_is_now is_now
          cfg = Marshal.load(Marshal.dump(is_now))
          # visit each Node and Leaf in the is_now tree
          # - clean up deserialization artifacts
          # - node_list is ordered for bottom-up sequence
          #   but here we work top down, so containers 
          #   will be created before we attempt to create
          #   their contents
          [@node_list.reverse, @leaf_list].flatten.each do |mapc|
            if mapc.olio.include? :ensure_is_class
              klass   = mapc.olio[:ensure_is_class]
              keypath = mapc.path_is_now
              value   = nested_value(cfg, keypath) \
                  do |hash, keys, index|
                    if index < keys.size - 1
                      PIN_NO_PARENT
                    else
                      parent = nested_value hash, keys[0..-2]
                      # note that parent[keys[-1]] has returned 
                      # nil; that's why we've reached this block
                      if parent.respond_to? :has_key? and parent.has_key? keys[-1]
                        PIN_NIL_VALUE
                      else
                        PIN_NO_VALUE
                      end
                    end
                  end
              case value
              when PIN_NO_PARENT, PIN_NO_VALUE
                # that's all, folks!
              when PIN_NIL_VALUE
                eligible = [::Array, ::Hash, ::String]
                if eligible.include? klass
                  value = klass.new
                else
                  fail "For #{mapc.full_name}: unable to create object of class #{klass} from nil"
                end
                nested_value_set cfg, keypath, value
              else
                unless value.class.eql? klass
                  if (klass.eql? ::Array) or (klass < ::Array)
                    value = [value]
                  elsif klass.respond_to? :new
                    begin
                      value = klass.new value
                    rescue
                      fail "For #{mapc.full_name}: unable to create object using #{klass}.new from value: #{value.inspect}"
                    end
                  else
                    value = \
                      case (s = String klass)
                      when 'String'   then String value
                      when 'Integer'  then Integer value
                      when 'Float'    then Float value
                      when 'Array'    then Array value
                      when 'Complex'  then value.to_c
                      when 'Rational' then value.to_r
                      else
                        fail "For #{mapc.full_name}: unable to create object of class #{klass} from value: #{value.inspect}"
                      end
                  end
                  nested_value_set cfg, keypath, value
                end
              end
            end
          end
          cfg
        end
        alias annotate_is_now prep_is_now

        private

        def walk_down(hash, key_path, leaf_list, node_list)
          # recursive depth-first tree walk
          # if val is a Hash:
          #   * key_path.push key
          #   * recurse
          #   * key_path.pop
          # if val is LeafData:
          #   * add :path_should => key_path to val
          #   * leaf_list.push Leaf.new(val)
          # if val is Node:
          #   * add :path_should => key_path to val
          #   * node_list.push Node.new(val)
          # else:
          #   * exception
          hash.each_pair do |key, value|
            case value
            when LeafData, NodeData
              true
            when Hash
              key_path.push key
              value[Node][:xml_attr]  = value.keys.
                  select{|k| (k =~ /^@/)}.
                  map   {|k| k.to_s}
              value[Node][:xml_order] = value.keys.
                  reject{|k| (k =~ /^@/) or (k == Node)}.
                  map   {|k| k.to_s}
              walk_down value, key_path, leaf_list, node_list
              key_path.pop
            else
              fail "Unexpected value: #{value.class} '#{value.inspect}'"
            end
          end
          hash.each_pair do |key, value|
            case value
            when LeafData
              value[:path_should] = key_path.dup << key
              leaf_list.push(Leaf.new value)
            when NodeData
              value[:path_should] = key_path.dup
              node_list.push(Node.new value)
            end
          end
        end

        def requires_for_inheritable_policy
          #
          # path notes for 'inherited' leaf:
          # path[0..-1]                my path
          # path[0..-2]                path to my container, my parent
          # path[0..-3]                path to my container's container,
          #                            my grandparent
          # path[0..-2] + [:sib]       path to my sibling property 'sib',
          #                            which should require me
          # path[0..-3] + [:inherited] path to 'inherited' property that
          #                            is a child of my grandparent (an 
          #                            aunt, say), which I should require
          # 
          @leaf_list.
            # find each leaf of type InheritedPolicyInherited 
            select{|leaf| leaf.misc.include? InheritablePolicyInherited}.
            each  {|leaf_mine|

              # require my 'aunt' inherited property, if there is one
              path_mine = leaf_mine.path_should
              if path_mine.size >= 2 # don't try to back up above root
                path_aunt = path_mine[0..-3] + [:inherited]
                aunt = @leaf_list.find{|l| l.path_should == path_aunt}
                leaf_mine.requires.push aunt.prop_name unless 
                  aunt.nil? or leaf_mine.requires.include? aunt.prop_name
              end

              # add myself as a requirement for each non-exempt sibling
              # and also mark it as InheritablePolicyValue so it will use
              # insyncInheritablePolicyValue -- not modular, but...
              name_mine = leaf_mine.prop_name
              path_prefix_sib = path_mine[0..-2]
              @leaf_list.
                select{|leaf| leaf.path_should[0..-2] == path_prefix_sib}.
                reject{|leaf| leaf.prop_name == name_mine}.
                reject{|sib|  sib.misc.include? InheritablePolicyExempt}.
                tap   {|siblings|  
                  siblings.
                    reject{|sib| sib.requires.include? name_mine}.
                    each  {|sib| sib.requires.push name_mine}
                  siblings.
                    reject{|sib| sib.misc.include? InheritablePolicyValue}.
                    each  {|sib| sib.misc.push InheritablePolicyValue}
                }
            }
        end

        def requires_for_requires_siblings
          # resolve requires_siblings (path-based) to requires (prop_names)
          @leaf_list.
            reject{|leaf| leaf.requires_siblings.empty?}.
            each  {|leaf|
              leaf.requires_siblings.each do |sib|
                case leaf.path_is_now[-1]
                when Symbol
                  sib = sib.to_sym
                when String
                  sib = sib.to_s
                end
                sib_path = leaf.path_is_now[0..-2] + [sib]
                sib_leaf = @leaf_list.find{|l| l.path_is_now == sib_path}
                if sib_leaf
                  leaf.requires.push sib_leaf.prop_name.to_sym unless
                    leaf.requires.include? sib_leaf.prop_name.to_sym
                else
                  fail "Not found: sibling #{sib.inspect} for '#{leaf.full_name}'"
                end
              end
            }
        end

      end

=begin

This is a set of tiny utilities for defining validation and munging
routines in the input tree for Map. Some are simply static blocks wrapped
in Proc, while others allow tailoring the block to specific cases.

=end

      def self.munge_to_i
        Proc.new {|v| v.to_i}
      end

      def self.munge_to_tfsyms
        Proc.new do |v|
          case v
          when FalseClass then :false
          when TrueClass  then :true
          else v
          end
        end
      end

      def self.munge_to_sym
        Proc.new do |v|
          v.to_sym if String === v
        end
      end

      def self.validate_i_ge(low)
        Proc.new do |v|
          v = Integer v
          fail "value #{v} not greater than nor equal to #{low}" unless low <= v
        end
      end

      def self.validate_i_le(high)
        Proc.new do |v|
          v = Integer v
          fail "value #{v} not less than nor equal to #{high}" unless v <= high
        end
      end

      def self.validate_i_in(range)
        Proc.new do |v|
          v = Integer v
          fail "value #{v} not in '#{range.inspect}'" unless range.include? v
        end
      end

=begin

This is a version of insync? for InheritablePolicy 'value'
properties. It looks at the current (is_now) and desired (should)
values of 'inheritable' (finding it at the same level of nesting)
to determine whether the property of interest should be considered
to be 'in sync'. If that can't be determined, the calling routine
should call the normal insync for the property's class.

Here's what usage looks like in the type:

  newproperty(:foo, ...) do
    :
    def insync?(is)
      v = PuppetX::VMware::Mapper.
          insyncInheritablePolicyValue is, @resource, :foo
      v = super(is) if v.nil?
      v
    end
    :
  end

XXX TODO fix this to return a block, to directly call super(is)
XXX TODO fix this to return a block, to directly use @resource
XXX TODO fix this to hold prop_name in a closure, so the caller 
         doesn't have to fool around with eval and interpolation
         when automatically generating newproperty

=end

      def self.insyncInheritablePolicyValue is, resource, prop_name

        provider = resource.provider
        map = provider.map

        # find the leaf for the value to be insync?'d
        leaf_value = map.leaf_list.find do |leaf|
          leaf.prop_name == prop_name
        end

        # for the corresponding 'inherited' value, generate the path
        path_is_now_inherited = leaf_value.path_is_now[0..-2].dup.push(:inherited)

        # for the corresponding 'inherited' value, find leaf, get prop_name
        prop_name_inherited = map.leaf_list.find do |leaf|
                                leaf.path_is_now == path_is_now_inherited
                              end.prop_name

        # get 'is_now' value for 'inherited' from provider
        is_now_inherited = provider.send "#{prop_name_inherited}".to_sym
        # get 'should' value for 'inherited' from resource
        should_inherited = resource[prop_name_inherited]
        # munge
        is_now_inherited = munge_to_tfsyms.call is_now_inherited
        should_inherited = munge_to_tfsyms.call should_inherited
#require 'pry';binding.pry

        case [is_now_inherited, should_inherited]
        # 'should' be inherited, so current value is ignored
        when [:true,  :true]  ; then return false
        when [:false, :true]  ; then return false
        # was inherited, but should be no longer - must supply all values
        when [:true, :false]  ; then return false
        # value is and should be uninherited, so normal insync?
        when [:false, :false] ; then return nil
        else
          return nil if is_now_inherited.nil?
          fail "For InheritedPolicy #{leaf_value.full_name}, "\
            "current '.inherited' is '#{is_now_inherited.inspect}', "\
            "requested '.inherited' is '#{should_inherited.inspect}'"
        end
      end
  
    end
  end
end
