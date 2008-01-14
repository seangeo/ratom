# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require 'xml/libxml'
require 'activesupport'

module Atom
  def self.parse(io)
    raise ArgumentError, "Atom.parse expects an instance of IO" unless io.is_a?(IO)
    
    Feed.new(XML::Reader.new(io.read))
  end
  
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
  
  class Generator
    include Parseable
    
    attr_reader :name
    attribute :uri, :version
    
    def initialize(xml)
      @name = xml.read_string.strip
      parse(xml, :once => true)
    end
  end
    
  class Person
    include Parseable
    element :name, :uri, :email
    
    def initialize(xml)
      xml.read
      parse(xml)
    end
  end
  
  class Content
    def self.parse(xml)
      case xml['type']
      when "xhtml"
        Xhtml.new(xml)
      when "html"
        Html.new(xml)
      else
        Text.new(xml)
      end
    end
  
    class Base < SimpleDelegator
      include Parseable      
      attribute :type, :'xml:lang'
      
      def initialize(xml, content = "")
        super(content)
        parse(xml, :once => true)
      end
      
      protected
      def set_content(c)
        __setobj__(c)
      end
    end
    
    class Text < Base    
      def initialize(xml)
        super(xml, xml.read_string)
      end
    end
    
    class Html < Base
      def initialize(xml)
        super(xml, xml.read_string.gsub(/\s+/, ' ').strip)
      end
    end
    
    class Xhtml < Base
      def initialize(xml)
        super(xml)
        
        starting_depth = xml.depth
        
        # Get the next element - should be a div according to the atom spec
        while xml.read == 1 && xml.node_type != XML::Reader::TYPE_ELEMENT; end
        
        if xml.name == 'div' && xml.namespace_uri == 'http://www.w3.org/1999/xhtml'
          set_content(xml.read_inner_xml.strip)
        else
          set_content(xml.read_outer_xml)
        end
        
        # get back to the end of the element we were created with
        while xml.read == 1 && xml.depth > starting_depth; end
      end
    end
  end
   
  class Feed
    include Parseable
    extend Forwardable
    def_delegators :@links, :alternate, :self
        
    element :id, :rights
    element :generator, :class => Generator
    element :title, :subtitle, :class => Content
    element :updated, :class => Time, :content_only => true
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
  end
  
  class Entry
    include Parseable
    extend Forwardable
    def_delegators :@links, :alternate, :self, :alternates, :enclosures
    
    element :title, :id, :summary
    element :updated, :published, :class => Time, :content_only => true
    element :content, :class => Content
    elements :links
    elements :authors, :contributors, :class => Person
        
    def initialize(xml)
      @links = Links.new
      @authors = []
      @contributors = []
      
      if current_node_is?(xml, 'entry')
        xml.read
        parse(xml)
      else
        raise ArgumentError, "Entry created with node other than atom:entry: #{xml.name}"
      end
    end
  end
  
  class Links < DelegateClass(Array)
    include Enumerable
    
    def initialize
      super([])
    end
    
    def alternate
      detect { |link| link.rel.nil? || link.rel == 'alternate' }
    end
    
    def alternates
      select { |link| link.rel.nil? || link.rel == 'alternate' }
    end
    
    def self
      detect { |link| link.rel == 'self' }
    end
    
    def enclosures
      select { |link| link.rel == 'enclosure' }
    end
  end
  
  class Link
    include Parseable
    attribute :href, :rel, :type, :length
        
    def initialize(xml)
      if current_node_is?(xml, 'link')
        parse(xml, :once => true)
      else
        raise ArgumentError, "Link created with node other than atom:link: #{xml.name}"
      end
    end
    
    def length=(v)
      @length = v.to_i
    end
    
    def to_s
      self.href
    end
  end
end
