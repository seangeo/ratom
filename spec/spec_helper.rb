begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'atom'

Spec::Runner.configure do |config|

  def mock_response(klass, body, headers = {})
    response = klass.new(nil, nil, nil)
    response.stub!(:body).and_return(body)
    
    headers.each do |k, v|
      response.stub!(:[]).with(k).and_return(v)
    end
    
    response
  end
end
