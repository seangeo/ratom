# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

$:.unshift File.dirname(__FILE__)

require 'xml/libxml'
require 'activesupport'

module Atom
  def self.parse(io)
    raise ArgumentError, "Atom.parse expects an instance of IO" unless io.is_a?(IO)
    
    Feed.new(XML::Reader.new(io.read))
  end
  
  module Parser
    def parse(xml, options = {})
      loop do
        case xml.node_type
        when XML::Reader::TYPE_ELEMENT
          if simple_elements.include?(xml.name)
            self.send("#{xml.name}=", xml.read_string)
          elsif date_elements.include?(xml.name)
            self.send("#{xml.name}=", Time.parse(xml.read_string))
          elsif collection_elements.include?(xml.name)            
            self.send("#{xml.name.pluralize}") << member(xml)
          elsif attributes.any?
            while (xml.move_to_next_attribute == 1)
              if attributes.include?(xml.name)
                self.send("#{xml.name}=", xml.value)
              end
            end
          end
        end
        break unless !options[:once] && xml.next == 1
      end
    end
    
    def member(xml)
      "Atom::#{xml.name.capitalize}".constantize.new(xml)
    end
    
    def next_node_is?(xml, element)
      xml.next == 1 && current_node_is?(xml, element)
    end
      
    def current_node_is?(xml, element)
      xml.node_type == XML::Reader::TYPE_ELEMENT && xml.name == element
    end
  end
  
  module Parseable
    #simple_elements = []
    #date_elements = []
    #collection_elements = []
    #attributes = []
    
    def Parseable.included(o)
      o.send(:cattr_accessor, :simple_elements, :date_elements, :collection_elements, :attributes)
      o.simple_elements = []
      o.date_elements = []
      o.collection_elements = []
      o.attributes = []
      o.send(:extend, Definitions)
    end
    
    module Definitions
      def element(*names)
        names.each do |name|
          attr_accessor name
          self.simple_elements << name.to_s
        end
      end
      
      def date_element(*names)
        names.each do |name|
          attr_accessor name
          self.date_elements << name.to_s
        end
      end
      
      def elements(*names)
        names.each do |name|
          attr_accessor name
          self.collection_elements << name.to_s.singularize
        end
      end
      
      def attribute(*names)
        names.each do |name|
          attr_accessor name
          self.attributes << name.to_s
        end
      end
    end
  end
  
  class Feed
    include Parser
    include Parseable
    extend Forwardable
    def_delegator :@links, :alternate
        
    element :title, :id
    date_element :updated
    elements :links, :entries
    
    def initialize(xml)
      @links, @entries = Links.new, []
      
      begin
        if next_node_is?(xml, 'feed')
          xml.read
          parse(xml)
        else
          raise ArgumentError, "XML document was missing atom:feed"        
        end
      ensure
        xml.close
      end
    end
    
    private
    def position_xml(xml)
     
    end        
  end
  
  class Entry
    include Parser
    include Parseable
    extend Forwardable
    def_delegators :@links, :alternate
    attr_accessor :title, :id, :updated, :summary, :links
    
    element :title, :id, :summary
    date_element :updated
    elements :links
        
    def initialize(xml)
      @links = Links.new
      if current_node_is?(xml, 'entry')
        xml.read
        parse(xml)
      else
        raise ArgumentError, "Entry created with node other than atom:entry: #{xml.name}"
      end
    end
  end
  
  class Links
    extend Forwardable
    include Enumerable
    def_delegators :@links, :<<, :size, :each
    
    def initialize
      @links = []
    end
    
    def alternate
      @links.first
    end         
  end
  
  class Link
    include Parser
    include Parseable
    attribute :href
    
    def initialize(xml)
      if current_node_is?(xml, 'link')
        parse(xml, :once => true)
      else
        raise ArgumentError, "Link created with node other than atom:link: #{xml.name}"
      end
    end
  end
end
