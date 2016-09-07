describe DataPackage::Package do

    before(:each) do
        FakeWeb.clean_registry
        FakeWeb.allow_net_connect = false
    end

    context "creating a package" do

      it "allows initialization without an object or string" do
        package = DataPackage::Package.new
      end
      
    end

    context "when parsing packages" do
        it "should initialize from an object" do
            package = {
                "name" => "test-package",
                "description" => "description",
                "resources" => [ { "path" => "data.csv" }]
            }
            package = DataPackage::Package.new(package)
            expect( package.name ).to eql("test-package")
            expect( package.resources.length ).to eql(1)
        end

        it "should support reading properties directly" do
            package = {
                "name" => "test-package",
                "description" => "description",
                "my-property" => "value"
            }
            package = DataPackage::Package.new(package)
            expect( package.property("my-property") ).to eql("value")
            expect( package.property("another-property") ).to eql(nil)
            expect( package.property("another-property", "default") ).to eql("default")
        end

        it "should load from a local file" do
            package = DataPackage::Package.new( test_package_filename )
            expect( package.name ).to eql("test-package")
            expect( package.title ).to eql("Test Package")
            expect( package.description ).to eql("Description")
            expect( package.homepage ).to eql("http://example.org")
            expect( package.version ).to eql("0.0.1")
            [:sources, :maintainers, :publisher, :contributors].each do |key|
                expect( package.send(key) ).to eql([])
            end
            expect( package.dependencies ).to eql(nil)
            expect( package.sources ).to eql([])
            expect( package.keywords ).to eql( [ "test", "testing" ] )
            expect( package.last_modified ).to eql( DateTime.parse("2013-12-05") )
            expect( package.image ).to eql(nil)
            expect( package.resources.length ).to eql(1)
        end

        it "should load from a directory" do
            package = DataPackage::Package.new( File.join( File.dirname(__FILE__), "test-pkg"),
                {:default_filename=>"valid-datapackage.json"})
            expect( package.name ).to eql("test-package")
            expect( package.resources.length ).to eql(1)
        end

        it "should load from am explicit URL" do
            FakeWeb.register_uri(:get, "http://example.com/datapackage.json",
                :body => File.read( test_package_filename ) )
            package = DataPackage::Package.new( "http://example.com/datapackage.json" )
            expect( package.name ).to eql("test-package")
            expect( package.resources.length ).to eql(1)
        end

        it "should load from a base URL" do
            FakeWeb.register_uri(:get, "http://example.com/datapackage.json",
                :body => File.read( test_package_filename ) )
            package = DataPackage::Package.new( "http://example.com/" )
            expect( package.name ).to eql("test-package")
            expect( package.resources.length ).to eql(1)
        end

        it "should distinguish between local and remote packages" do
            package = DataPackage::Package.new( { "name" => "test"} )
            expect( package.local? ).to eql(true)
            expect( package.base ).to eql("")

            file = test_package_filename
            package = DataPackage::Package.new(file)
            expect( package.local? ).to eql(true)
            expect( package.base ).to eql( File.join( File.dirname(__FILE__),"test-pkg") )

            FakeWeb.register_uri(:get, "http://example.com/datapackage.json",
                :body => File.read( test_package_filename ) )
            package = DataPackage::Package.new( "http://example.com/" )
            expect( package.local? ).to eql(false)
            expect( package.base ).to eql( "http://example.com" )
        end

    end

    #We're just testing simple validation options here, there are separate
    #specs for testing the validators and the individual schemas
    context "when validating with the datapackage profile" do
        it "should validate basic datapackage structure" do
            package = DataPackage::Package.new(test_package_filename)
            expect( package.valid? ).to be(true)
            expect( package.valid?(:datapackage, true) ).to be(true)
            messages = package.validate
            expect( messages[:errors] ).to eql([])
            expect( messages[:warnings] ).to eql([])
        end

        it "should detect invalid datapackages" do
            package = DataPackage::Package.new( { "name" => "this is invalid" } )
            expect( package.valid? ).to be(false)
        end
    end

end
