describe DataPackage::Resource do

  context "returns the right type of resource" do

    it "for a local resource" do
      resource = {
        'path' => test_package_filename('test.csv')
      }

      expect(DataPackage::Resource.load(resource)).to be_a_kind_of(DataPackage::LocalResource)
    end

    it "for a remote resource" do
      resource = {
        'url' => 'http://example.com/test.csv'
      }

      expect(DataPackage::Resource.load(resource)).to be_a_kind_of(DataPackage::RemoteResource)
    end

    it "for a inline resource" do
      resource = {
        'data' => 'whevs'
      }

      expect(DataPackage::Resource.load(resource)).to be_a_kind_of(DataPackage::InlineResource)
    end

    it "prefers inline data over a path" do
      resource = {
        'path' => test_package_filename('test.csv'),
        'data' => 'whevs'
      }

      expect(DataPackage::Resource.load(resource)).to be_a_kind_of(DataPackage::InlineResource)
    end

    it "prefers local data over remote data" do
      resource = {
        'path' => test_package_filename('test.csv'),
        'url' => 'http://example.com/test.csv'
      }

      expect(DataPackage::Resource.load(resource)).to be_a_kind_of(DataPackage::LocalResource)
    end

    it "prefers inline data over a url" do
      resource = {
        'url' => 'http://example.com/test.csv',
        'data' => 'whevs'
      }

      expect(DataPackage::Resource.load(resource)).to be_a_kind_of(DataPackage::InlineResource)
    end

    it "returns a local resource when forced to" do
      resource = {
        'url' => 'http://example.com/test.csv'
      }

      expect(DataPackage::Resource.load(resource, '', { local: true })).to be_a_kind_of(DataPackage::LocalResource)
    end

  end

end
