require 'simplecov'
require 'simplecov-rcov'
require 'fakeweb'
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start

require 'datapackage'
require 'fakeweb'

RSpec.configure do |config|
  config.order = "random"
end

def load_schema(filename)
    JSON.parse( File.read( File.join( File.dirname(__FILE__), "..", "etc", filename ) ) )
end

def fully_validate(schema, data)
    JSON::Validator.fully_validate(schema, data, :errors_as_objects => true)
end
