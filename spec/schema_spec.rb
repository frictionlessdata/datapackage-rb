describe DataPackage::Schema do

  context 'initialize' do

    it 'loads a schema from a hash' do
      schema_hash = {
        foo: 'bar'
      }
      schema = DataPackage::Schema.new(schema_hash)

      expect(schema).to eq(schema_hash)
      expect(schema['foo']).to eq(schema_hash['foo'])
    end

    it 'loads a schema from a path' do
      path = File.join('spec', 'fixtures', 'fake_schema.json')

      schema = DataPackage::Schema.new(path)

      expect(schema).to eq ({
        'key' => 'value'
      })
    end

    it 'loads a schema from a url' do
      url = 'http://example.org/thing.json'
      body = File.read File.join('spec', 'fixtures', 'fake_schema.json')

      FakeWeb.register_uri(:get, url, :body => body)

      schema = DataPackage::Schema.new(url)

      expect(schema).to eq ({
        'key' => 'value'
      })
    end

    it 'loads a schema from the registry' do
      schema = DataPackage::Schema.new(:base)

      expect(schema['properties'].count).to eq 13
    end

    it 'loads a schema from a custom registry' do
      registry_path = File.join('spec', 'fixtures', 'base_registry.csv')
      schema_path = File.join('spec', 'fixtures', 'fake_schema.json')

      registry_url = 'http://some-place.com/registry.csv'

      FakeWeb.register_uri(:get, registry_url, :body => File.read(registry_path))
      FakeWeb.register_uri(:get, 'http://example.com/one.json', :body => File.read(schema_path))

      schema = DataPackage::Schema.new(:base, registry_url: registry_url)

      expect(schema).to eq ({
        'key' => 'value'
      })
    end

    context 'derefences a schema' do

      specify 'with a file' do
        path = File.join('spec', 'fixtures', 'referenced-schema.json')

        schema = DataPackage::Schema.new(path)

        expect(schema['properties']['name']).to eq({
          "propertyOrder" => 10,
          "title" => "Name",
          "type" => "string"
        })
      end

      specify 'with a url' do
        url = 'http://example.org/thing.json'

        schema = File.read File.join('spec', 'fixtures', 'referenced-schema.json')
        definitions = File.read File.join('spec', 'fixtures', 'definitions.json')

        FakeWeb.register_uri(:get, url, :body => schema)
        FakeWeb.register_uri(:get, 'http://example.org/definitions.json', :body => definitions)

        schema = DataPackage::Schema.new(url)

        expect(schema['properties']['name']).to eq({
          "propertyOrder" => 10,
          "title" => "Name",
          "type" => "string"
        })
      end

      specify 'with a url in a subdirectory' do
        url = 'http://example.org/schema/thing.json'

        schema = File.read File.join('spec', 'fixtures', 'referenced-schema.json')
        definitions = File.read File.join('spec', 'fixtures', 'definitions.json')

        FakeWeb.register_uri(:get, url, :body => schema)
        FakeWeb.register_uri(:get, 'http://example.org/schema/definitions.json', :body => definitions)

        schema = DataPackage::Schema.new(url)

        expect(schema['properties']['name']).to eq({
          "propertyOrder" => 10,
          "title" => "Name",
          "type" => "string"
        })
      end

      specify 'from a registry' do
        schema = DataPackage::Schema.new(:base)

        expect(schema['properties']['name']).to eq({
          "propertyOrder" => 10,
          "title" => "Name",
          "description" => "An identifier for this package. Lower case characters with '.', '_' and '-' are allowed.",
          "type" => "string",
          "pattern" => "^([a-z0-9._-])+$"
        })
      end
    end

    context 'nested referencing' do
      specify 'from a file' do
        path = File.join('spec', 'fixtures', 'nested-referenced-schema.json')

        schema = DataPackage::Schema.new(path)

        expect(schema['properties']['nested-for-some-reason']['name']).to eq({
          "propertyOrder" => 10,
          "title" => "Nested name",
          "type" => "string"
        })

        expect(schema).to eq ({
          "$schema" => "http://json-schema.org/draft-04/schema#",
          "description" => "Data Package is a simple specification for data access and delivery.",
          "properties" => {
            "nested-for-some-reason" => {
              "name" => {
                "propertyOrder" => 10,
                "title" => "Nested name",
                "type" => "string"
              }
            }
          },
          "required" => [
            "name"
          ],
          "title" => "Data Package",
          "type" => "object"
        })
      end

      context 'references within references' do
        specify 'turtles all the way down' do
          path = File.join('spec', 'fixtures', 'nested-nested-schema.json')
          schema = DataPackage::Schema.new(path)

          expect(schema).to eq ({
            "$schema" => "http://json-schema.org/draft-04/schema#",
            "description" => "Data Package is a simple specification for data access and delivery.",
            "properties" => {
              "extra-nested-for-some-reason" => {
                "name" => {
                  "propertyOrder" => 10,
                  "title" => "Nested thing",
                  "type" => "string"
                }
              }
            },
            "required" => [
              "name"
            ],
            "title" => "Data Package",
            "type" => "object"
          })
        end
      end
    end

    context 'raises an error' do

      it 'when the path does not exist' do
        path = File.join('spec', 'fixtures', 'not_a_path.json')

        expect { DataPackage::Schema.new(path) }.to raise_exception { |exception|
          expect(exception).to be_a DataPackage::SchemaException
          expect(exception.status).to eq ("Path 'spec/fixtures/not_a_path.json' does not exist")
        }

      end

      it 'when the path is not json' do
        path = File.join('spec', 'fixtures', 'not_a_json')

        expect { DataPackage::Schema.new(path) }.to raise_exception { |exception|
          expect(exception).to be_a DataPackage::SchemaException
          expect(exception.status).to eq ("Schema is not valid JSON")
        }
      end

      it 'when the url is not json' do
        url = 'http://example.org/thing.json'
        body = File.read File.join('spec', 'fixtures', 'not_a_json')

        FakeWeb.register_uri(:get, url, :body => body)

        expect { DataPackage::Schema.new(url) }.to raise_exception { |exception|
          expect(exception).to be_a DataPackage::SchemaException
          expect(exception.status).to eq ("Schema is not valid JSON")
        }
      end

      it 'when the url does not exist' do
        url = 'http://bad.org/terrible.json'

        FakeWeb.register_uri(:get, url, :body => "", :status => ["404", "Not Found"])

        expect { DataPackage::Schema.new(url) }.to raise_exception { |exception|
          expect(exception).to be_a DataPackage::SchemaException
          expect(exception.message).to eq ("Schema URL returned 404 Not Found")
        }
      end

      it 'when the schema is not a string, hash or symbol' do
        a = [1, 2, 3]

        expect { DataPackage::Schema.new(a) }.to raise_exception { |exception|
          expect(exception).to be_a DataPackage::SchemaException
          expect(exception.message).to eq ("Schema must be a URL, path, Hash or registry-identifier")
        }
      end

      it 'when the schema is invalid'

    end

  end

  context 'validate' do

    before(:each) do
      @schema = DataPackage::Schema.new(:base)
      @valid_datapackage = JSON.parse(File.read File.join('spec', 'test-pkg', 'valid-datapackage.json'))
      @invalid_datapackage = JSON.parse(File.read File.join('spec', 'fixtures', 'invalid-datapackage.json'))
    end

    it 'validates correctly' do
      skip "This doesn't work yet"

      expect(@schema.valid?(@valid_datapackage)).to eq(true)
    end

    it 'returns errors' do
      expect(@schema.valid?(@invalid_datapackage)).to eq(false)

      errors = @schema.validation_errors(@invalid_datapackage)
      expect(errors.count).to eq(2)
      expect(errors).to eq([
        "The property '#/' did not contain a required property of 'name' in schema ccfffe25-174d-53ba-aa73-f63a5565bdb9#",
        "The property '#/resources/0/name' value \"Test Data\" did not match the regex '^([a-z0-9._-])+$' in schema ccfffe25-174d-53ba-aa73-f63a5565bdb9#"
      ])
    end

    it 'retuns no errors if data is valid' do
      expect(@schema.validation_errors(@valid_datapackage).count).to eq(0)
    end

  end

end
