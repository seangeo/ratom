require 'atom'

#
# Media extension (see http://video.search.yahoo.com/mrss)
#
# Exaple:
#     f.entries << Atom::Entry.new do |e|
#       e.media_content = Media.new :url => article.media['image']
#     end
#

class Media
    include Atom::Xml::Parseable
    include Atom::SimpleExtensions
    attribute :url, :fileSize, :type, :medium, :isDefault, :expression, :bitrate, :height, :width, :duration, :lang

    def initialize(o = {})
      case o
      when XML::Reader
        parse(o, :once => true)
      when Hash
        o.each do |k, v|
          self.send("#{k.to_s}=", v)
        end
      else
        raise ArgumentError, "Got #{o.class} but expected a Hash or XML::Reader"
      end

      yield(self) if block_given?
    end
end

Atom::Feed.add_extension_namespace :media, "http://search.yahoo.com/mrss/"
Atom::Entry.element "media:content", :class => Media

