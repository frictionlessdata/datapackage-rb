describe DataPackage::RemoteResource do

  before(:each) do
    @url = 'http://example.com/test.csv'
    FakeWeb.register_uri(:get, @url,
        :body => File.read( test_package_filename('test.csv') ) )
  end

  it 'returns the resource' do
    resource_hash = {
      'foo' => 'bar',
      'url' => @url
    }

    resource = DataPackage::RemoteResource.new(resource_hash)

    expect(resource).to eq(resource_hash)
  end

  it 'loads the data from a url' do
    resource_hash = {
      'foo' => 'bar',
      'url' => @url
    }

    resource = DataPackage::RemoteResource.new(resource_hash)
    expect(resource.data).to eq(File.read(test_package_filename('test.csv')))
  end

  it 'loads the data with a base url' do
    resource_hash = {
      'foo' => 'bar',
      'path' => 'test.csv'
    }

    base_url = 'http://example.com/'

    resource = DataPackage::RemoteResource.new(resource_hash, base_url)
    expect(resource.data).to eq(File.read(test_package_filename('test.csv')))
  end

end
