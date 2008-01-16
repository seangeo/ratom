# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require 'net/http'

module Atom
  module Xml
    module Parseable
      def parse(xml, options = {})
        starting_depth = xml.depth
        loop do
          case xml.node_type
          when XML::Reader::TYPE_ELEMENT
            if element_specs.include?(xml.local_name)
              element_specs[xml.local_name].parse(self, xml)
            elsif attributes.any?
              while (xml.move_to_next_attribute == 1)
                if attributes.include?(xml.name)
                  # Support attribute names with namespace prefixes
                  self.send("#{xml.name.sub(/:/, '_')}=", xml.value)
                end
              end
            end
          end
          break unless !options[:once] && xml.next == 1 && xml.depth >= starting_depth
        end
      end
    
      def next_node_is?(xml, element, ns = nil)
        xml.next == 1 && current_node_is?(xml, element)
      end
      
      def current_node_is?(xml, element, ns = nil)
        xml.node_type == XML::Reader::TYPE_ELEMENT && xml.local_name == element && (ns.nil? || ns == xml.namespace_uri)
      end
  
      def Parseable.included(o)
        o.send(:cattr_accessor, :element_specs, :attributes)
        o.element_specs = {}
        o.attributes = []
        o.send(:extend, DeclarationMethods)
      end
    
      module DeclarationMethods
        def element(*names)
          options = {:type => :single}
          options.merge!(names.pop) if names.last.is_a?(Hash) 
        
          names.each do |name|
            attr_accessor name          
            self.element_specs[name.to_s] = ParseSpec.new(name, options)
          end
        end
            
        def elements(*names)
          options = {:type => :collection}
          options.merge!(names.pop) if names.last.is_a?(Hash)
        
          names.each do |name|
            attr_accessor name
            self.element_specs[name.to_s.singularize] = ParseSpec.new(name, options)
          end
        end
      
        def attribute(*names)
          names.each do |name|
            attr_accessor name.to_s.sub(/:/, '_').to_sym
            self.attributes << name.to_s
          end
        end
      
        def loadable!(&error_handler)
          class_name = self.name
          (class << self; self; end).instance_eval do
            define_method "load_#{class_name.demodulize.downcase}" do |o|
               xml = nil
                case o
                when String
                  xml = XML::Reader.new(o)
                when IO
                  xml = XML::Reader.new(o.read)
                when URI
                  raise ArgumentError, "Service.load_service only handles http URIs" if o.scheme != 'http'
                  xml = XML::Reader.new(Net::HTTP.get_response(o).body)
                else
                  raise ArgumentError, "Service.load_service needs String, URI or IO"
                end

                if error_handler
                  xml.set_error_handler(&error_handler)
                else
                  xml.set_error_handler do |reader, message, severity, base, line|
                    if severity == XML::Reader::SEVERITY_ERROR
                      raise ParseError, "#{message} at #{line}"
                    end
                  end
                end
                
                self.new(xml)
            end
          end
        end
        
        def parse(xml)
          new(xml)
        end
      end
    
      # Contains the specification for how an element should be parsed.
      #
      # This should not need to be constructed directly, instead use the
      # element and elements macros in the declaration of the class.
      #
      # See Parseable.
      #
      class ParseSpec
        attr_reader :name, :options
      
        def initialize(name, options = {})
          @name = name.to_s
          @attribute = name.to_s.sub(/:/, '_')
          @options = options
        end
      
        # Parses a chunk of XML according the specification.
        # The data extracted will be assigned to the target object.
        #
        def parse(target, xml)
          case options[:type]
          when :single
            target.send("#{@attribute}=".to_sym, build(target, xml))
          when :collection
            target.send("#{@attribute}") << build(target, xml)
          end
        end
      
        private
        # Create a member 
        def build(target, xml)
          if options[:class].is_a?(Class)
            if options[:content_only]
              options[:class].parse(xml.read_string)
            else
              options[:class].parse(xml)
            end
          elsif options[:type] == :single
            xml.read_string
          elsif options[:content_only] 
            xml.read_string
          else
            target_class = target.class.name
            target_class = target_class.sub(/#{target_class.demodulize}$/, name.singularize.capitalize)
            target_class.constantize.parse(xml)
          end
        end
      end
    end
  end
end