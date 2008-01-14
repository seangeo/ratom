# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module Atom
  module Xml
    module Parseable
      def parse(xml, options = {})
        starting_depth = xml.depth
        loop do
          case xml.node_type
          when XML::Reader::TYPE_ELEMENT
            if element_specs.include?(xml.name)
              element_specs[xml.name].parse(self, xml)
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
    
      def next_node_is?(xml, element)
        xml.next == 1 && current_node_is?(xml, element)
      end
      
      def current_node_is?(xml, element)
        xml.node_type == XML::Reader::TYPE_ELEMENT && xml.name == element
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
            target.send("#{@attribute}=".to_sym, build(xml))
          when :collection
            target.send("#{@attribute}") << build(xml)
          end
        end
      
        private
        # Create a member 
        def build(xml)
          if options[:class].is_a?(Class)
            if options[:content_only]
              options[:class].parse(xml.read_string)
            else
              options[:class].parse(xml)
            end
          elsif options[:type] == :single
            xml.read_string
          else
            "Atom::#{name.singularize.capitalize}".constantize.parse(xml)
          end
        end
      end
    end
  end
end