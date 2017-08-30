describe DataPackage::Resource do

  let(:tabular_resource) {
    {
      'name'=> 'tabular_resource',
      'data'=> [['str', 'int'], [1,2]],
      'schema'=> {
        'fields'=> [
          {
            'name'=> 'str',
          },
          {
            'name'=> 'int',
            'type'=> 'integer',
          }
        ]
      },
      'profile'=> DataPackage::DEFAULTS[:resource][:tabular_profile],
    }
  }

  context 'initialize' do

    it "raises if the resource doesn't have 'path' or 'data' " do
      resource_hash = {
        'name'=> 'resource',
        'foo'=> 'bar',
      }

      expect{ DataPackage::Resource.new(resource_hash) }.to raise_error(DataPackage::ResourceException)
    end

    it 'extends the resource with defaults' do
      resource_hash = {
        'name'=> 'resource',
        'data'=> 'whevs',
      }
      expected_resource = resource_hash.merge!({
        'profile'=> DataPackage::DEFAULTS[:resource][:profile],
        'encoding'=> DataPackage::DEFAULTS[:resource][:encoding],
      })
      resource = DataPackage::Resource.new(resource_hash)

      expect(resource).to eq(expected_resource)
    end

    it 'extends a tabular resource with table defaults' do
      resource = DataPackage::Resource.new(tabular_resource)

      expect(resource['schema']['missingValues']).to eq(DataPackage::DEFAULTS[:schema][:missing_values])
      expect(resource['schema']['fields'][0]['type']).to eq(DataPackage::DEFAULTS[:schema][:type])
      expect(resource['schema']['fields'][0]['format']).to eq(DataPackage::DEFAULTS[:schema][:format])
    end

    context 'remote resource' do

      before(:each) do
        @url = 'http://example.com/test.csv'
        FakeWeb.register_uri(:get, @url,
            :body => File.read( test_package_filename('test.csv') ) )
      end

      it 'correctly detects source_type' do
        resource_hash = {
          'name' => 'remote resource',
          'path' => @url
        }
        resource = DataPackage::Resource.new(resource_hash)

        expect(resource.remote).to eq(true)
      end

      it 'accepts full URL as source' do
        resource_hash = {
          'name' => 'remote resource',
          'path' => @url
        }
        resource = DataPackage::Resource.new(resource_hash)

        expect(resource.source).to eq(@url)
      end

      it 'constructs source from a base URL' do
        file = 'test.csv'
        resource_hash = {
          'name' => 'remote resource',
          'path' => file,
        }
        base_url = 'http://example.com/'
        resource = DataPackage::Resource.new(resource_hash, base_url)

        expect(resource.source).to eq(URI.join(base_url, file).to_s)
      end

    end

    context 'local resource' do

      before(:each) do
        @base_path =  File.dirname(test_package_filename)
      end

      it 'correctly detects source_type' do
        resource_hash = {
          'name' => 'local resource',
          'path' => 'test.csv'
        }
        resource = DataPackage::Resource.new(resource_hash, @base_path)

        expect(resource.local).to eq(true)
      end

      it 'constructs source from a base path' do
        file = 'test.csv'
        resource_hash = {
          'name' => 'local resource',
          'path' => file,
        }
        resource = DataPackage::Resource.new(resource_hash, @base_path)

        expect(resource.source).to eq(File.join(@base_path, file).to_s)
      end

      it 'raises if absolute path is given' do
        resource_hash = {
          'name' => 'local resource',
          'path' => test_package_filename('test.csv')
        }

        expect{ DataPackage::Resource.new(resource_hash) }.to raise_error(DataPackage::ResourceException)
      end

    end

    context 'inline resource' do

      it 'correctly detects source_type' do
        resource_hash = {
          'name' => 'inline resource',
          'data' => 'whevs'
        }
        resource = DataPackage::Resource.new(resource_hash)

        expect(resource.inline).to eq(true)
      end

      it 'returns the data' do
        resource_hash = {
          'name' => 'bar',
          'data' => 'whevs'
        }
        resource = DataPackage::Resource.new(resource_hash)

        expect(resource.source).to eq('whevs')
      end

    end
  end

  context 'validate' do

    it 'should validate basic resource structure' do
      resource = DataPackage::Resource.new({
        'name'=> 'resource',
        'data'=> 'random',
      })

      expect(resource.valid?).to be true
      expect(resource.validate).to be true
      expect(resource.iter_errors{ |err| err }).to be_empty
    end

    it 'should detect an invalid resource' do
      schemaless = tabular_resource.reject{|k,v| k.to_s == 'schema'}
      resource = DataPackage::Resource.new(schemaless)

      expect(resource.valid?).to be false
      expect{ resource.validate }.to raise_error(DataPackage::ValidationError)
      expect(resource.iter_errors{ |err| err }).to_not be_empty
    end

  end

  context 'tabular' do

    it 'is true for resources with tabular profile' do
      resource = DataPackage::Resource.new(tabular_resource)

      expect(resource.tabular?).to be true
    end

    it 'is true for resources that comply with the tabular profile' do
      resource = DataPackage::Resource.new(tabular_resource.merge({
        'profile'=> DataPackage::DEFAULTS[:resource][:profile],
      }))

      expect(resource.tabular?).to be true
    end

    it 'is false for resources that don\'t comply with tabular profile' do
      resource = DataPackage::Resource.new({
        'name'=> 'resource',
        'data'=> 'random',
      })

      expect(resource.tabular?).to be false
    end

  end

  context 'table' do

    it 'returns a table for tabular resources' do
      expect(DataPackage::Resource.new(tabular_resource).table.class).to eq(TableSchema::Table)
    end

    it 'returns nil for a non-tabular resources' do
      resource = DataPackage::Resource.new({
        'name'=> 'resource',
        'data'=> 'random',
      })

      expect(resource.table).to eq(nil)
    end

  end

  context 'read' do

    it 'reads tabular data' do
      resource = DataPackage::Resource.new(tabular_resource)
      expect(resource.headers).to eq(['str', 'int'])
      expect(resource.schema.field_names).to eq(['str', 'int'])
      expect(resource.read).to eq([['1', 2]])
      expect(resource.read(keyed: true)).to eq([{'str'=> '1', 'int'=> 2}])
    end

  end

end
