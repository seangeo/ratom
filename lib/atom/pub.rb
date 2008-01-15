# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require 'atom/xml/parser'
require 'xml/libxml'

module Atom
  module Pub
    NAMESPACE = 'http://www.w3.org/2007/app'
    
    def self.parse(io)
      raise ArgumentError, "Service.parse needs an IO" unless io.respond_to?(:read)
      xml = XML::Reader.new(io.read)
      Service.parse(xml)
    end
    
    class Service
      include Atom::Xml::Parseable      
      elements :workspaces
      
      def initialize(xml)
        @workspaces = []
        begin
          if next_node_is?(xml, 'service', Atom::Pub::NAMESPACE)
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
    
    class Categories
      include Atom::Xml::Parseable
      
      def initialize(o)
        o.read
        parse(o)
      end
    end
    
    class Workspace
      include Atom::Xml::Parseable
      element :title, :class => Content
      elements :collections
      
      def initialize(o)
        @collections = []
        o.read
        parse(o)
      end
    end
    
    class Collection
      include Atom::Xml::Parseable
      attribute :href
      element :categories, :class => Categories
      element :title, :class => Content
      elements :accepts, :content_only => true
      
      def initialize(o)
        @accepts = []
        # do it once to get the attributes
        parse(o, :once => true)
        # now step into the element and the sub tree
        o.read
        parse(o)
      end
    end    
  end  
end
