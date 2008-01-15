# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require 'rubygems'
require 'xml/libxml'
require 'activesupport'
require 'atom/xml/parser.rb'

module Atom
  class ParseError < StandardError; end
  
  NAMESPACE = 'http://www.w3.org/2005/Atom' unless defined?(NAMESPACE)
  
  def self.parse(io)
    raise ArgumentError, "Atom.parse expects an instance of IO" unless io.respond_to?(:read)
    
    xml = XML::Reader.new(io.read)
    xml.set_error_handler do |reader, msg, severity, base, line|
      if severity == XML::Reader::SEVERITY_ERROR
        raise ParseError, "Error on line #{line}: #{msg}"
      end
    end
    
    Feed.new(xml)
  end
    
  class Generator
    include Xml::Parseable
    
    attr_reader :name
    attribute :uri, :version
    
    def initialize(xml)
      @name = xml.read_string.strip
      parse(xml, :once => true)
    end
  end
    
  class Person
    include Xml::Parseable
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
      include Xml::Parseable      
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
      XHTML = 'http://www.w3.org/1999/xhtml'
      
      def initialize(xml)
        super(xml)
        
        starting_depth = xml.depth
        
        # Get the next element - should be a div according to the atom spec
        while xml.read == 1 && xml.node_type != XML::Reader::TYPE_ELEMENT; end
        
        if xml.local_name == 'div' && xml.namespace_uri == XHTML
          set_content(xml.read_inner_xml.strip.gsub(/\s+/, ' '))
        else
          set_content(xml.read_outer_xml)
        end
        
        # get back to the end of the element we were created with
        while xml.read == 1 && xml.depth > starting_depth; end
      end
    end
  end
   
  class Source
    extend Forwardable
    def_delegators :@links, :alternate, :self, :alternates, :enclosures
    include Xml::Parseable
    
    element :id
    element :updated, :class => Time, :content_only => true
    element :title, :subtitle, :class => Content
    elements :authors, :contributors, :class => Person
    elements :links
    
    def initialize(xml)
      unless current_node_is?(xml, 'source', NAMESPACE)
        raise ArgumentError, "Invalid node for atom:source - #{xml.name}(#{xml.namespace})"
      end
      
      @authors, @contributors, @links = [], [], Links.new
      
      xml.read
      parse(xml)
    end
  end
  
  class Feed
    include Xml::Parseable
    extend Forwardable
    def_delegators :@links, :alternate, :self, :first_page, :last_page, :next_page, :prev_page
        
    element :id, :rights
    element :generator, :class => Generator
    element :title, :subtitle, :class => Content
    element :updated, :class => Time, :content_only => true
    elements :links, :entries
    
    def initialize(xml)
      @links, @entries = Links.new, []
      
      begin
        if next_node_is?(xml, 'feed', Atom::NAMESPACE)
          xml.read
          parse(xml)
        else
          raise ArgumentError, "XML document was missing atom:feed"        
        end
      ensure
        xml.close
      end
    end
    
    def first?
      links.self == links.first_page
    end 
    
    def last?
      links.self == links.last_page
    end
  end
  
  class Entry
    include Xml::Parseable
    extend Forwardable
    def_delegators :@links, :alternate, :self, :alternates, :enclosures
    
    element :title, :id, :summary
    element :updated, :published, :class => Time, :content_only => true
    element :content, :class => Content
    element :source, :class => Source
    elements :links
    elements :authors, :contributors, :class => Person
        
    def initialize(xml)
      @links = Links.new
      @authors = []
      @contributors = []
      
      if current_node_is?(xml, 'entry', Atom::NAMESPACE)
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
    
    def alternate(type = nil)
      detect { |link| (link.rel.nil? || link.rel == Link::Rel::ALTERNATE) && (type.nil? || type == link.type) }
    end
    
    def alternates(type = nil)
      select { |link| link.rel.nil? || link.rel == Link::Rel::ALTERNATE }
    end
    
    def self
      detect { |link| link.rel == Link::Rel::SELF }
    end
    
    def enclosures
      select { |link| link.rel == Link::Rel::ENCLOSURE }
    end
    
    def first_page
      detect { |link| link.rel == Link::Rel::FIRST }
    end
    
    def last_page
      detect { |link| link.rel == Link::Rel::LAST }
    end
    
    def next_page
      detect { |link| link.rel == Link::Rel::NEXT }
    end
    
    def prev_page
      detect { |link| link.rel == Link::Rel::PREVIOUS }
    end
  end
  
  class Link
    module Rel
      ALTERNATE = 'alternate'
      SELF = 'self'
      ENCLOSURE = 'enclosure'
      FIRST = 'first'
      LAST = 'last'
      PREVIOUS = 'prev'
      NEXT = 'next'
    end    
    
    include Xml::Parseable
    attribute :href, :rel, :type, :length
        
    def initialize(o)
      case o
      when XML::Reader
        if current_node_is?(o, 'link')
          parse(o, :once => true)
        else
          raise ArgumentError, "Link created with node other than atom:link: #{o.name}"
        end
      when Hash
        [:href, :rel, :type, :length].each do |attr|
          self.send("#{attr}=", o[attr])
        end
      else
        raise ArgumentError, "Don't know how to handle #{o}"
      end        
    end
    
    def length=(v)
      @length = v.to_i
    end
    
    def to_s
      self.href
    end
    
    def ==(o)
      o.respond_to?(:href) && o.href == self.href
    end
    
    def fetch
      content = Net::HTTP.get_response(URI.parse(self.href)).body
      
      begin
        Atom.parse(StringIO.new(content))
      rescue ArgumentError, ParseError => ae
        content
      end
    end
  end
end
