describe DataPackage::Resource do

  context 'remote resource' do

    before(:each) do
      @url = 'http://example.com/test.csv'
      FakeWeb.register_uri(:get, @url,
          :body => File.read( test_package_filename('test.csv') ) )
    end

    it 'returns the resource' do
      resource_hash = {
        'foo' => 'bar',
        'path' => @url
      }

      resource = DataPackage::Resource.new(resource_hash)

      expect(resource).to eq(resource_hash)
    end

    it 'loads the data from a url' do
      resource_hash = {
        'foo' => 'bar',
        'path' => @url
      }

      resource = DataPackage::Resource.new(resource_hash)
      expect(resource.data).to eq(File.read(test_package_filename('test.csv')))
    end

    it 'loads the data with a base url' do
      resource_hash = {
        'foo' => 'bar',
        'path' => 'test.csv'
      }

      base_url = 'http://example.com/'

      resource = DataPackage::Resource.new(resource_hash, base_url)
      expect(resource.data).to eq(File.read(test_package_filename('test.csv')))
    end

  end

  context 'local resource' do

    it 'returns the resource' do
      resource_hash = {
        'foo' => 'bar',
        'path' => test_package_filename('test.csv')
      }

      resource = DataPackage::Resource.new(resource_hash)

      expect(resource).to eq(resource_hash)
    end

    it 'loads the data lazily' do
      resource_hash = {
        'foo' => 'bar',
        'path' => test_package_filename('test.csv')
      }

      resource = DataPackage::Resource.new(resource_hash)
      expect(resource.data).to eq(File.read(test_package_filename('test.csv')))
    end

    it 'loads the data with a base path' do
      resource_hash = {
        'foo' => 'bar',
        'path' => 'test.csv'
      }

      base_path = File.join( File.dirname(__FILE__), "fixtures", "test-pkg" )

      resource = DataPackage::Resource.new(resource_hash, base_path)
      expect(resource.data).to eq(File.read(test_package_filename('test.csv')))
    end

  end

  context 'inline resource' do

    it 'returns the resource' do
      resource_hash = {
        'foo' => 'bar',
        'data' => 'whevs'
      }

      resource = DataPackage::Resource.new(resource_hash)

      expect(resource).to eq(resource_hash)
    end

    it 'returns the data' do
      resource_hash = {
        'foo' => 'bar',
        'data' => 'whevs'
      }

      resource = DataPackage::Resource.new(resource_hash)
      expect(resource.data).to eq('whevs')
    end

  end

  it "raises if the resource doesn't have 'path' or 'data' " do
    resource_hash = {
      'foo' => 'bar'
    }

    expect{ DataPackage::Resource.new(resource_hash) }.to raise_error(DataPackage::ResourceException)
  end

end
