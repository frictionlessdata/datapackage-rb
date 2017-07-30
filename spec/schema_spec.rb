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
      schema = DataPackage::Schema.new('tabular-data-package')

      expect(schema).to_not be_empty
    end

    it 'loads a schema from a custom registry' do
      registry_path = File.join('spec', 'fixtures', 'base_registry.json')
      schema_path = File.join('spec', 'fixtures', 'fake_schema.json')

      registry_url = 'http://some-place.com/registry.json'

      FakeWeb.register_uri(:get, registry_url, :body => File.read(registry_path))
      FakeWeb.register_uri(:get, 'http://example.com/one.json', :body => File.read(schema_path))

      schema = DataPackage::Schema.new('base', registry_url: registry_url)

      expect(schema).to eq ({
        'key' => 'value'
      })
    end

    context 'raises an error' do

      it 'when the path does not exist' do
        path = File.join('spec', 'fixtures', 'not_a_path.json')

        expect { DataPackage::Schema.new(path) }.to raise_exception { |exception|
          expect(exception).to be_a DataPackage::SchemaException
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
          expect(exception.message).to eq ("Schema must be a URL, path, Hash or registry identifier")
        }
      end

    end

  end

  context 'validate' do

    before(:each) do
      @schema = DataPackage::Schema.new('data-package')
      @valid_datapackage = JSON.parse(File.read File.join('spec', 'fixtures', 'test-pkg', 'valid-datapackage.json'))
      @invalid_datapackage = JSON.parse(File.read File.join('spec', 'fixtures', 'invalid-datapackage.json'))
    end

    it 'validates correctly' do
      expect(@schema.valid?(@valid_datapackage)).to eq(true)
    end

    it 'returns errors' do
      expect(@schema.valid?(@invalid_datapackage)).to eq(false)

      errors = @schema.validation_errors(@invalid_datapackage)
      expect(errors.count).to eq(2)
    end

    it 'retuns no errors if data is valid' do
      expect(@schema.validation_errors(@valid_datapackage).count).to eq(0)
    end

  end

end
