module Atom
  module Extensions
    class Property
      include Atom::Xml::Parseable

      namespace "http://custom.namespace"
      attribute :name, :value

      def initialize(name = nil, value = nil)
        if name && value
          initialize_with_o :name => name, :value => value
        else
          initialize_with_o(name) { yield if block_given? }
        end
      end

      def initialize_with_o(o = nil)
        case o
        when String, XML::Reader
          parse o, :once => true
        when Hash
          o.each do |name,value|
            self.send :"#{name}=", value
          end
        else
          yield(self) if block_given?
        end
      end
    end  
  end
end
