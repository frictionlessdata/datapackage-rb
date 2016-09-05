require 'coveralls'
Coveralls.wear!
require 'fakeweb'

require 'datapackage'

RSpec.configure do |config|
  config.order = "random"
  config.tty = true
end

def load_schema(filename)
  JSON.parse( File.read( File.join( File.dirname(__FILE__), "..", "etc", filename ) ) )
end

def fully_validate(schema, data)
  JSON::Validator.fully_validate(schema, data, :errors_as_objects => true)
end

def test_package_filename(filename="valid-datapackage.json")
  File.join( File.dirname(__FILE__), "test-pkg", filename )
end
