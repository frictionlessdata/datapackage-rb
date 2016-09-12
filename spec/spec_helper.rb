require 'coveralls'
Coveralls.wear!

require 'fakeweb'

FakeWeb.allow_net_connect = %r[^https?:\/\/coveralls.io.+$]

require 'datapackage'

RSpec.configure do |config|
  config.order = "random"
  config.tty = true
end

def test_package_filename(filename="valid-datapackage.json")
  File.join( File.dirname(__FILE__), "fixtures", "test-pkg", filename )
end
