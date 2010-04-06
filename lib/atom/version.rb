require 'yaml'
module Atom
  module VERSION
    INFO = YAML.load_file(File.join(File.dirname(__FILE__), "..", "..", "VERSION.yml"))
    STRING = [:major, :minor, :patch, :build].map {|l| INFO[l]}.compact.join('.')
  end
end
