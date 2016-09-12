describe DataPackage::InlineResource do

  it 'returns the resource' do
    resource_hash = {
      'foo' => 'bar'
    }

    resource = DataPackage::InlineResource.new(resource_hash)

    expect(resource).to eq(resource_hash)
  end

  it 'returns the data' do
    resource_hash = {
      'foo' => 'bar',
      'data' => 'whevs'
    }

    resource = DataPackage::InlineResource.new(resource_hash)
    expect(resource.data).to eq('whevs')
  end

end
