# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require 'forwardable'
require 'rubygems'
require 'xml/libxml'
require 'activesupport'
require 'atom/xml/parser.rb'

module Atom
  class ParseError < StandardError; end
  NAMESPACE = 'http://www.w3.org/2005/Atom' unless defined?(NAMESPACE)
      
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
    
    def initialize(o = {})
      case o
      when XML::Reader
        o.read
        parse(o)
      when Hash
        o.each do |k, v|
          self.send("#{k.to_s}=", v)
        end
      end
    end
    
    def inspect
      "<Atom::Person name:'#{name}' uri:'#{uri}' email:'#{email}"
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
  
    class Base < DelegateClass(String)
      include Xml::Parseable
      attribute :type, :'xml:lang'
            
      def initialize(c)
        __setobj__(c)
      end
      
      def ==(o)
        if o.is_a?(self.class)
          self.type == o.type &&
           self.xml_lang == o.xml_lang &&
           self.to_s == o.to_s
        elsif o.is_a?(String)
          self.to_s == o
        end
      end
            
      protected
      def set_content(c)
        __setobj__(c)
      end
    end
    
    class Text < Base    
      def initialize(xml)
        super(xml.read_string)
        parse(xml, :once => true)
      end
    end
    
    class Html < Base
      def initialize(o)
        case o
        when XML::Reader
          super(o.read_string.gsub(/\s+/, ' ').strip)
          parse(o, :once => true)
        when String
          super(o)
          @type = 'html'
        end        
      end
      
      def to_xml(nodeonly = true, name = 'content')
        node = XML::Node.new(name)
        node << self.to_s
        node['type'] = 'html'
        node['xml:lang'] = self.xml_lang        
        node
      end
    end
    
    class Xhtml < Base
      XHTML = 'http://www.w3.org/1999/xhtml'
      
      def initialize(xml)        
        parse(xml, :once => true)
        starting_depth = xml.depth
        
        # Get the next element - should be a div according to the atom spec
        while xml.read == 1 && xml.node_type != XML::Reader::TYPE_ELEMENT; end
        
        if xml.local_name == 'div' && xml.namespace_uri == XHTML
          super(xml.read_inner_xml.strip.gsub(/\s+/, ' '))
        else
          super(xml.read_outer_xml)
        end
        
        # get back to the end of the element we were created with
        while xml.read == 1 && xml.depth > starting_depth; end
      end
      
      def to_xml(nodeonly = true, name = 'content')
        node = XML::Node.new(name)
        node['type'] = 'xhtml'
        node['xml:lang'] = self.xml_lang
        
        div = XML::Node.new('div')        
        div['xmlns'] = XHTML
        div
        
        p = XML::Parser.string(to_s)
        content = p.parse.root.copy(true)
        div << content
        
        node << div
        node
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
    def_delegators :@links, :alternate, :self, :via, :first_page, :last_page, :next_page, :prev_page
        
    loadable! 
    
    element :id, :rights
    element :generator, :class => Generator
    element :title, :subtitle, :class => Content
    element :updated, :published, :class => Time, :content_only => true
    elements :links, :entries
    
    def initialize(o = {})
      @links, @entries = Links.new, []
      
      case o
      when XML::Reader
        if next_node_is?(o, 'feed', Atom::NAMESPACE)
          o.read
          parse(o)
        else
          raise ArgumentError, "XML document was missing atom:feed: #{o.read_outer_xml}"
        end
      when Hash
        o.each do |k, v|
          self.send("#{k.to_s}=", v)
        end
      end
      
      yield(self) if block_given?
    end
    
    def first?
      links.self == links.first_page
    end 
    
    def last?
      links.self == links.last_page
    end
    
    def reload!
      if links.self
        Feed.load_feed(URI.parse(links.self.href))
      end
    end
    
    def each_entry(options = {}, &block)
      if options[:paginate]
        since_reached = false
        feed = self
        loop do          
          feed.entries.each do |entry|
            if options[:since] && entry.updated && options[:since] > entry.updated
              since_reached = true
              break
            else
              block.call(entry)
            end
          end
          
          if since_reached || feed.next_page.nil?
            break
          else feed.next_page
            feed = feed.next_page.fetch 
          end
        end
      else
        self.entries.each(&block)
      end
    end
  end
  
  class Entry
    include Xml::Parseable
    extend Forwardable
    def_delegators :@links, :alternate, :self, :alternates, :enclosures, :edit_link, :via
    
    loadable!
    element :title, :id, :summary
    element :updated, :published, :class => Time, :content_only => true
    element :content, :class => Content
    element :source, :class => Source
    elements :links
    elements :authors, :contributors, :class => Person
        
    def initialize(o = {})
      @links = Links.new
      @authors = []
      @contributors = []
      
      case o
      when XML::Reader
        if current_node_is?(o, 'entry', Atom::NAMESPACE) || next_node_is?(o, 'entry', Atom::NAMESPACE)
          o.read
          parse(o)
        else
          raise ArgumentError, "Entry created with node other than atom:entry: #{o.name}"
        end
      when Hash
        o.each do |k,v|
          send("#{k.to_s}=", v)
        end
      end

      yield(self) if block_given?
    end   
    
    def reload!
      if links.self
        Entry.load_entry(URI.parse(links.self.href))
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
    
    def via
      detect { |link| link.rel == Link::Rel::VIA }
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
    
    def edit_link
      detect { |link| link.rel == 'edit' }
    end
  end
  
  class Link
    module Rel
      ALTERNATE = 'alternate'
      SELF = 'self'
      VIA = 'via'
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
        Atom::Feed.load_feed(content)
      rescue ArgumentError, ParseError => ae
        content
      end
    end
    
    def inspect
      "<Atom::Link href:'#{href}' type:'#{type}'>"
    end
  end
end
