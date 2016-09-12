describe DataPackage::Package do

    context "creating a package" do

      it "allows initialization without an object or string" do
        package = DataPackage::Package.new
        expect(package.name).to eq(nil)
      end

      it "allows properties to be set" do
        package = DataPackage::Package.new

        package.name = "My awesome datapackage"

        expect(package.name).to eq("My awesome datapackage")
        expect(package).to eq({"name" => "My awesome datapackage"})
      end

      it "uses the base schema by default" do
        package = DataPackage::Package.new

        expect(package.instance_variable_get("@schema")['title']).to eq('Data Package')
      end

      it "allows a schema to be specified" do
        schema = {'foo' => 'bar'}

        package = DataPackage::Package.new(nil, schema)

        expect(package.instance_variable_get("@schema")).to eq(schema)
      end

      context "allows a resource to be specified" do

        it "with a file" do
          file = test_package_filename('test.csv')

          package = DataPackage::Package.new

          package.resources << {
            'path' => file
          }

          expect(package.resources[0]).to be_a_kind_of(DataPackage::LocalResource)
          expect(package.resources[0].data).to eq(File.read(file))
        end

        it "with a url" do
          file = test_package_filename('test.csv')
          url = 'http://example.com/test.csv'

          FakeWeb.register_uri(:get, url, :body => File.read( file ) )

          package = DataPackage::Package.new

          package.resources << {
            'url' => url
          }

          expect(package.resources[0]).to be_a_kind_of(DataPackage::RemoteResource)
          expect(package.resources[0].data).to eq(File.read(file))
        end

        it "with inline data" do
          package = DataPackage::Package.new
          data = [
            ['foo', 'bar', 'baz']
          ]

          package.resources << {
            'data' => data
          }

          expect(package.resources[0]).to be_a_kind_of(DataPackage::InlineResource)
          expect(package.resources[0].data).to eq(data)
        end

      end

    end

    context "when parsing packages" do

      it "should initialize from an object" do
        package = {
            "name" => "test-package",
            "description" => "description",
            "resources" => [ { "path" => test_package_filename('test.csv') }]
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

      it "should allow properties to be changed" do
        package = {
            "name" => "test-package",
            "description" => "description",
            "my-property" => "value"
        }
        package = DataPackage::Package.new(package)
        package.name = 'new-package'

        expect(package.name).to eq('new-package')

        expect(package.to_h).to eq({
            "name" => "new-package",
            "description" => "description",
            "my-property" => "value"
        })
      end

      it "should load from a local file" do
          package = DataPackage::Package.new( test_package_filename )
          expect( package.name ).to eql("test-package")
          expect( package.title ).to eql("Test Package")
          expect( package.description ).to eql("Description")
          expect( package.homepage ).to eql("http://example.org")
          expect( package.version ).to eql("0.0.1")
          [:sources, :contributors].each do |key|
              expect( package.send(key) ).to eql([])
          end
          expect( package.dataDependencies ).to eql({})
          expect( package.sources ).to eql([])
          expect( package.keywords ).to eql( [ "test", "testing" ] )
          expect( package.image ).to eql(nil)
          expect( package.resources.length ).to eql(1)
      end

      it "should load from a zip file" do
        path = File.join( File.dirname(__FILE__), "fixtures", "test-pkg.zip" )

        package = DataPackage::Package.new( path )

        expect( package.name ).to eql("test-package")
        expect( package.title ).to eql("Test Package")
        expect( package.description ).to eql("Description")
        expect( package.homepage ).to eql("http://example.org")
        expect( package.version ).to eql("0.0.1")
        [:sources, :contributors].each do |key|
            expect( package.send(key) ).to eql([])
        end
        expect( package.dataDependencies ).to eql({})
        expect( package.sources ).to eql([])
        expect( package.keywords ).to eql( [ "test", "testing" ] )
        expect( package.image ).to eql(nil)
        expect( package.resources.length ).to eql(1)
      end

      it "should load from a directory" do
          package = DataPackage::Package.new( File.join( File.dirname(__FILE__), "test-pkg"), nil,
              {:default_filename=>"valid-datapackage.json"})
          expect( package.name ).to eql("test-package")
          expect( package.resources.length ).to eql(1)
      end

      it "should load from an explicit URL" do
          FakeWeb.register_uri(:get, "http://example.com/datapackage.json",
              :body => File.read( test_package_filename ) )
          package = DataPackage::Package.new( "http://example.com/datapackage.json" )
          expect( package.name ).to eql("test-package")
          expect( package.resources.length ).to eql(1)
      end

      it "should load from a zipfile at an explicit URL" do
          FakeWeb.register_uri(:get, "http://example.com/datapackage.zip",
              :body => File.read( File.join( File.dirname(__FILE__), "fixtures", "test-pkg.zip" ) ) )
          package = DataPackage::Package.new( "http://example.com/datapackage.zip" )
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

      context "parsing resources" do

        it "from a local file" do
          package = DataPackage::Package.new( test_package_filename )

          expect(package.resources[0].data).to eq(File.read(  File.join( File.dirname(__FILE__),"test-pkg", "test.csv") ))
        end

        it "from a local file with a relative path" do
          filename = File.join( File.dirname(__FILE__), 'fixtures', 'datapackage_with_foo.txt_resource.json' )
          package = DataPackage::Package.new(filename)

          expect(package.resources[0]).to be_a_kind_of(DataPackage::LocalResource)
          expect(package.resources[0].data).to eq("bar\n")
        end

        it "from a url" do
          FakeWeb.register_uri(:get, "http://example.com/datapackage.json",
              :body => File.read( test_package_filename ) )

          FakeWeb.register_uri(:get, "http://example.com/test.csv",
              :body => File.read( test_package_filename('test.csv') ) )

          package = DataPackage::Package.new( "http://example.com/datapackage.json" )

          expect(package.resources[0].data).to eq(File.read(  File.join( File.dirname(__FILE__),"test-pkg", "test.csv") ))
        end

        it "from a zipfile" do
          path = File.join( File.dirname(__FILE__), "fixtures", "test-pkg.zip" )

          package = DataPackage::Package.new( path )

          expect(package.resources[0].data).to eq(File.read(  File.join( File.dirname(__FILE__),"test-pkg", "test.csv") ))
        end

      end

    end

    context "validation" do

      it "should validate basic datapackage structure" do
        package = DataPackage::Package.new(test_package_filename)
        package.validate

        expect(package.valid?).to be(true)
        expect(package.errors).to eq([])
      end

      it "should set errors when valid? is passed" do
        package = DataPackage::Package.new(test_package_filename)
        expect(package.valid?).to be(true)
        expect(package.errors).to eq([])
      end

      it "should detect an invalid datapackage" do
        package = DataPackage::Package.new( { "name" => "this is invalid" } )
        expect( package.valid? ).to be(false)
      end

      it "should validate on the fly" do
        schema = {
            'properties' => {
                'name' => {}
            },
            'required' => ['name']
        }

        package = DataPackage::Package.new({}, schema)
        expect(package.valid?).to eq(false)

        package.name = 'A name'
        expect(package.valid?).to eq(true)
      end

    end

end
