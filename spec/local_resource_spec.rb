describe DataPackage::LocalResource do

  it 'returns the resource' do
    resource_hash = {
      'foo' => 'bar',
      'path' => test_package_filename('test.csv')
    }

    resource = DataPackage::LocalResource.new(resource_hash)

    expect(resource).to eq(resource_hash)
  end

  it 'loads the data lazily' do
    resource_hash = {
      'foo' => 'bar',
      'path' => test_package_filename('test.csv')
    }

    resource = DataPackage::LocalResource.new(resource_hash)
    expect(resource.data).to eq(File.read(test_package_filename('test.csv')))
  end

  it 'loads the data with a base path' do
    resource_hash = {
      'foo' => 'bar',
      'path' => 'test.csv'
    }

    base_path = File.join( File.dirname(__FILE__), "fixtures", "test-pkg" )

    resource = DataPackage::LocalResource.new(resource_hash, base_path)
    expect(resource.data).to eq(File.read(test_package_filename('test.csv')))
  end

end
