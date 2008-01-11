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
  end
  
  class AtomElement
    class_inheritable_array :simple_elements, :date_elements, :collection_elements, :attributes
    self.simple_elements = []
    self.date_elements = []
    self.collection_elements = []
    self.attributes = []
  end
  
  class Feed < AtomElement
    include Parser
    extend Forwardable
    def_delegator :@links, :alternate
    attr_accessor :title, :id, :updated, :links, :entries
        
    self.simple_elements = ['title', 'id']
    self.collection_elements = ['link', 'entry']
    self.date_elements = ['updated']
    
    def initialize(xml)
      @links, @entries = Links.new, []
      position_xml(xml)      
      parse(xml)      
      xml.close
    end
    
    private
    def position_xml(xml)
      # first element should be feed element
      unless xml.next == 1 && 
             xml.node_type == XML::Reader::TYPE_ELEMENT && 
             xml.name == 'feed'
        xml.close
        raise ArgumentError, "XML document missing feed element"
      else
        # step into the feed element
        xml.read
      end
    end        
  end
  
  class Entry < AtomElement
    include Parser
    extend Forwardable
    def_delegators :@links, :alternate
    attr_accessor :title, :id, :updated, :summary, :links
    self.simple_elements = ['title', 'id', 'summary']
    self.date_elements = ['updated']
    self.collection_elements = ['link']
        
    def initialize(xml)
      @links = Links.new
      xml.read
      parse(xml)
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
  
  class Link < AtomElement
    include Parser
    attr_accessor :href
    self.attributes = ['href']
    
    def initialize(xml)
      parse(xml, :once => true)
    end
  end
end
