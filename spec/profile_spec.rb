describe DataPackage::Profile do
  include DataPackage::Helpers

  context 'initialize' do

    it 'loads a profile from a url' do
      url = 'http://example.org/thing.json'
      body = File.read File.join('spec', 'fixtures', 'fake_profile.json')
      FakeWeb.register_uri(:get, url, :body => body)
      profile = DataPackage::Profile.new(url)

      expect(profile).to eq ({
        'key' => 'value'
      })
    end

    it 'loads a profile from the registry' do
      profile = DataPackage::Profile.new('tabular-data-package')

      expect(profile).to_not be_empty
    end

    context 'raises an error' do

      it 'when the url is not json' do
        url = 'http://example.org/thing.json'
        body = File.read File.join('spec', 'fixtures', 'not_a_json')
        FakeWeb.register_uri(:get, url, :body => body)

        expect { DataPackage::Profile.new(url) }.to raise_exception { |exception|
          expect(exception).to be_a DataPackage::ProfileException
          expect(exception.message).to eq ("Profile is not valid JSON")
        }
      end

      it 'when the url does not exist' do
        url = 'http://bad.org/terrible.json'
        FakeWeb.register_uri(:get, url, :body => "", :status => ["404", "Not Found"])

        expect { DataPackage::Profile.new(url) }.to raise_exception { |exception|
          expect(exception).to be_a DataPackage::ProfileException
          expect(exception.message).to eq ("Profile URL returned 404 Not Found")
        }
      end

      it 'when the profile id can\'t be found in the registry' do
        profile_id = 'no-such-profile'
        expect { DataPackage::Profile.new(profile_id) }.to raise_exception { |exception|
          expect(exception).to be_a DataPackage::ProfileException
          expect(exception.message).to start_with("Couldn't find profile with id `#{profile_id}`")
        }
      end

      it 'when the profile descriptor is not a string' do
        expect { DataPackage::Profile.new(200) }.to raise_exception { |exception|
          expect(exception).to be_a DataPackage::ProfileException
          expect(exception.message).to eq ("Profile must be a URL or registry identifier")
        }
      end

      it 'when the profile is not a JSON' do
        url = 'http://bad.org/not_a_json'
        body = File.read(File.join('spec', 'fixtures', 'not_a_json'))
        FakeWeb.register_uri(:get, url, :body => body)

        expect { DataPackage::Profile.new(url)}.to raise_exception{ |exception|
          expect(exception).to be_a DataPackage::ProfileException
          expect(exception.message).to eq('Profile is not valid JSON')
        }
      end

    end

  end

  context 'validation' do

    before(:each) do
      @profile = DataPackage::Profile.new('data-package')
      @valid_datapackage = JSON.parse(File.read File.join('spec', 'fixtures', 'test-pkg', 'valid-datapackage.json'))
      @invalid_datapackage = JSON.parse(File.read File.join('spec', 'fixtures', 'invalid-datapackage.json'))
    end

    context 'validate' do

      it 'if true for valid package' do
        expect(@profile.validate(@valid_datapackage)).to be true
      end

      it 'raises ValidationError for invalid package' do
        expect{ @profile.validate(@invalid_datapackage) }.to raise_error(DataPackage::ValidationError)
      end

    end

    context 'valid' do

      it 'is true for valid package' do
        expect(@profile.valid?(@valid_datapackage)).to be true
      end

      it 'is false for invalid package' do
        expect(@profile.valid?(@invalid_datapackage)).to be false
      end

    end

    context 'iter_errors' do

      it 'is empty when the package is valid' do
        errors = []
        @profile.iter_errors(@valid_datapackage){ |err| errors << err }
        expect(errors).to be_empty
      end

      it 'raises ValidationError for invalid package' do
        errors = []
        @profile.iter_errors(@invalid_datapackage){ |err| errors << err }
        expect(errors).to_not be_empty
      end

    end
  end

end
