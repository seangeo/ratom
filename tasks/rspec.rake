begin
  require 'spec/rake/spectask'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
end
begin
  require 'spec/rake/spectask'
rescue LoadError
  puts <<-EOS
To use rspec for testing you must install rspec gem:
    gem install rspec
EOS
  exit(0)
end
