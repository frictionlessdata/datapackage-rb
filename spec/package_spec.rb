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

      context "profile" do

        it "uses the base profile by default" do
          package = DataPackage::Package.new

          expect(package.profile).to be_a(DataPackage::Profile)
          expect(package.profile.name).to eq('data-package')
        end

        it "allows a custom profile to be specified" do
          profile_url = 'http://example.org/thing.json'
          profile_body = File.read File.join('spec', 'fixtures', 'fake_profile.json')
          FakeWeb.register_uri(:get, profile_url, :body => profile_body)
          package = DataPackage::Package.new({
              'profile' => profile_url
            })

          expect(package.profile).to eq({
            'key' => 'value'
          })
        end

      end

      context "allows a resource to be specified" do

        it "with a file" do
          file = 'test.csv'
          package = DataPackage::Package.new( test_package_filename )
          package.resources << {
            'name' => 'resource',
            'path' => file
          }

          expect(package.resources[0]).to be_a_kind_of(DataPackage::Resource)
          expect(package.resources[0].source).to eq(File.join(package.base, file))
        end

        it "with a url" do
          url = 'http://example.com/test.csv'
          FakeWeb.register_uri(:get, url, body: '')
          package = DataPackage::Package.new
          package.resources << {
            'name' => 'resource',
            'path' => url
          }

          expect(package.resources[0]).to be_a_kind_of(DataPackage::Resource)
          expect(package.resources[0].source).to eq(url)
        end

        it "with inline data" do
          package = DataPackage::Package.new
          data = [
            ['foo', 'bar', 'baz']
          ]

          package.resources << {
            'name' => 'resource',
            'data' => data
          }

          expect(package.resources[0]).to be_a_kind_of(DataPackage::Resource)
          expect(package.resources[0].source).to eq(data)
        end

      end

    end

    context "when parsing packages" do

      it "should initialize from an object" do
        package = {
            "name" => "test-package",
            "description" => "description",
            "resources" => [ { "name" => "resource", "data" => "test" }]
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
          expect( package.created ).to eq(nil)
          expect( package.homepage ).to eql("http://example.org")
          [:sources, :contributors].each do |key|
              expect( package.send(key) ).to eql([])
          end
          expect( package.sources ).to eql([])
          expect( package.keywords ).to eql( [ "test", "testing" ] )
          expect( package.resources.length ).to eql(1)
      end

      it "should load from a zip file" do
        path = File.join( File.dirname(__FILE__), "fixtures", "test-pkg.zip" )

        package = DataPackage::Package.new(path)

        expect( package.name ).to eql("test-package")
        expect( package.title ).to eql("Test Package")
        expect( package.description ).to eql("Description")
        expect( package.created ).to eq(nil)
        expect( package.homepage ).to eql({ "path"=> "http://example.org" })
        [:sources, :contributors].each do |key|
            expect( package.send(key) ).to eql([])
        end
        expect( package.sources ).to eql([])
        expect( package.keywords ).to eql( [ "test", "testing" ] )
        expect( package.resources.length ).to eql(1)
      end

      it "should load from a directory" do
        package = DataPackage::Package.new(File.join( File.dirname(__FILE__), "fixtures", "test-pkg"),
          opts: {:default_filename=>"valid-datapackage.json"})
        expect( package.name ).to eql("test-package")
        expect( package.resources.length ).to eql(1)
      end

      it "should load from an explicit URL" do
          FakeWeb.register_uri(:get, "http://example.com/datapackage.json",
              :body => File.read( test_package_filename ) )
          FakeWeb.register_uri(:get, "http://example.com/test.csv",
              :body => File.read( test_package_filename('test.csv') ) )
          package = DataPackage::Package.new( "http://example.com/datapackage.json" )
          expect( package.name ).to eql("test-package")
          expect( package.resources.length ).to eql(1)
      end

      it "should load from a zipfile at an explicit URL" do
          package_body = File.read( File.join( File.dirname(__FILE__), "fixtures", "test-pkg.zip" ) )
          FakeWeb.register_uri(:get, "http://example.com/datapackage.zip",
            :body => package_body)
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
          expect( package.base ).to eql( File.join( File.dirname(__FILE__), "fixtures", "test-pkg") )

          FakeWeb.register_uri(:get, "http://example.com/datapackage.json",
              :body => File.read( test_package_filename ) )
          package = DataPackage::Package.new( "http://example.com/" )
          expect( package.local? ).to eql(false)
          expect( package.base ).to eql( "http://example.com" )
      end

    end

    context "tabular datapackages" do

      it "returns a table" do
        package = DataPackage::Package.new( test_package_filename )
        expect(package.resources[0].table.class).to eq(TableSchema::Table)
      end

      it "table contains data in tabular form" do
        package = DataPackage::Package.new( test_package_filename )
        data = package.resources[0].table.rows(keyed: true)
        expect(data).to eq([
          {"ID"=>"abc", "Price"=>100},
          {"ID"=>"def", "Price"=>300},
          {"ID"=>"ghi", "Price"=>750}
        ])
      end

      it 'table returns nil for non-tabular packages' do
        filename = File.join( File.dirname(__FILE__), 'fixtures', 'datapackage_with_foo.txt_resource.json' )
        package = DataPackage::Package.new( filename )

        expect(package.resources[0].table).to eq(nil)
      end

    end

    context "validation" do

      it "should validate basic datapackage structure" do
        package = DataPackage::Package.new(test_package_filename)
        package.validate

        expect(package.valid?).to be(true)
        expect(package.errors).to eq([])
      end

      it "should detect an invalid datapackage" do
        package = DataPackage::Package.new( { "name" => "this is invalid" } )
        expect( package.valid? ).to be(false)
      end

      it "should validate on the fly" do
        profile_body = {
            'properties' => {
                'name' => {}
            },
            'required' => ['name']
        }
        profile_url = 'http://example.org/my_profile.json'
        FakeWeb.register_uri(:get, profile_url, :body => JSON.dump(profile_body))

        package = DataPackage::Package.new({
            'profile' =>  profile_url
        })
        expect(package.valid?).to eq(false)

        package.name = 'A name'
        expect(package.valid?).to eq(true)
      end

    end

end
