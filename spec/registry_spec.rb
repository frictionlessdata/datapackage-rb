require 'spec_helper'

describe DataPackage::Registry do

  before(:each) do
    @base_registry_path = File.join('spec', 'fixtures', 'base_registry.json')
    @empty_registry_path = File.join('spec', 'fixtures', 'empty_registry.json')
    @base_and_tabular_registry_path = File.join('spec', 'fixtures', 'base_and_tabular_registry.json')
    @unicode_registry_path = File.join('spec', 'fixtures', 'unicode_registry.json')
    @base_profile_path = File.join('spec', 'fixtures', 'base_profile.json')
  end

  context 'initialize' do

    before(:each) do
      @url = 'http://some-place.com/registry.json'
      @body = File.read(@base_registry_path)
    end

    it 'accepts urls' do
      FakeWeb.register_uri(:get, @url, :body => @body)

      registry = DataPackage::Registry.new(@url)

      expect(registry.available_profiles.values.count).to eq(1)
      expect(registry.available_profiles['base']).to eq({
          'id'=> 'base',
          'title'=> 'Data Package',
          'schema'=> 'http://example.com/one.json',
          'specification'=> 'http://example.com'
      })
    end

    it 'has a default registry url' do
      default_url = 'https://specs.frictionlessdata.io/schemas/registry.json'

      expect(DataPackage::Registry::DEFAULT_REGISTRY_URL).to eq(default_url)
    end

    it 'accepts a path' do
      registry = DataPackage::Registry.new(@base_registry_path)

      expect(registry.available_profiles.values.count).to eq(1)
      expect(registry.available_profiles['base']).to eq({
          'id'=> 'base',
          'title'=> 'Data Package',
          'schema'=> 'http://example.com/one.json',
          'specification'=> 'http://example.com'
      })
    end

  end

  context 'raises an error' do

    it 'if registry is not a JSON' do
      url = 'http://some-place.com/registry.txt'

      FakeWeb.register_uri(:get, url, :body => "foo")

      expect {
        DataPackage::Registry.new(url)
      }.to raise_error(DataPackage::RegistryError)
    end

    it 'if registry has no ID field' do
      url = 'http://some-place.com/registry.txt'

      FakeWeb.register_uri(:get, url, :body => "foo\nbar")

      expect {
        DataPackage::Registry.new(url)
      }.to raise_error(DataPackage::RegistryError)
    end

    it 'if registry webserver raises error' do
      url = 'http://some-place.com/registry.txt'

      FakeWeb.register_uri(:get, url, :body => "", :status => ["500", "Internal Server Error"])

      expect {
        DataPackage::Registry.new(url)
      }.to raise_error(DataPackage::RegistryError)
    end

    it 'registry url does not exist' do
      url = 'http://some-place.com/registry.txt'

      FakeWeb.register_uri(:get, url, :body => "", :status => ["404", "Not Found"])

      expect {
        DataPackage::Registry.new(url)
      }.to raise_error(DataPackage::RegistryError)
    end

    it 'registry path does not exist' do
      path = "some/fake/path/file.csv"

      expect {
        DataPackage::Registry.new(path)
      }.to raise_error(DataPackage::RegistryError)
    end

  end

  context 'available profiles' do

    it 'available profiles returns empty hash when registry is empty' do
      registry = DataPackage::Registry.new(@empty_registry_path)

      expect(registry.available_profiles).to eq({})
    end

    it 'returns list of profiles' do
      registry = DataPackage::Registry.new(@base_and_tabular_registry_path)

      expect(registry.available_profiles.values.count).to eq(2)
      expect(registry.available_profiles['base']).to eq({
          'id'=> 'base',
          'title'=> 'Data Package',
          'schema'=> 'http://example.com/one.json',
          'schema_path'=> 'base_profile.json',
          'specification'=> 'http://example.com'
      })
      expect(registry.available_profiles['tabular']).to eq({
          'id'=> 'tabular',
          'title'=> 'Tabular Data Package',
          'schema'=> 'http://example.com/two.json',
          'schema_path'=> 'tabular_profile.json',
          'specification'=> 'http://example.com'
      })
    end

    it 'cannot be set' do
      registry = DataPackage::Registry.new(@base_and_tabular_registry_path)
      expect { registry.available_profiles = {} }.to raise_error(NoMethodError)
    end

    it 'works with unicode strings' do
      registry = DataPackage::Registry.new(@unicode_registry_path)

      expect(registry.available_profiles.values.count).to eq(2)
      base_profile_metadata = registry.available_profiles['base']
      expect(base_profile_metadata['title']).to eq('Iñtërnâtiônàlizætiøn')
    end

  end

  context 'get' do

    it 'loads profile from disk' do
      registry = DataPackage::Registry.new(@base_and_tabular_registry_path)

      base_profile = registry.get('base')
      expect(base_profile).to_not eq(nil)
      expect(base_profile['title']).to eq('base_profile')
    end

    it 'loads remote file if local copy does not exist' do
      registry = [
        {
          'id'=> "base",
          'title'=> "Data Package",
          'schema'=> "http://example.com/one.json",
          'schema_path'=> "inexistent.json",
          'specification'=> "http://example.com"
        }
      ]

      profile_url = 'http://example.com/one.json'
      profile_body = '{ "title": "base_profile" }'

      FakeWeb.register_uri(:get, profile_url, :body => profile_body)

      tempfile = Tempfile.new('.json')
      tempfile.write(JSON.dump(registry))
      tempfile.rewind

      registry = DataPackage::Registry.new(tempfile.path)

      base_profile = registry.get('base')
      expect(base_profile).to_not eq(nil)
      expect(base_profile['title']).to eq('base_profile')
    end

    context 'raises an error' do

      it 'if profile is not json' do
        registry_path = File.join('spec', 'fixtures', 'registry_nonjson_profile.json')
        registry = DataPackage::Registry.new(registry_path)

        expect { registry.get('notajson') }.to raise_error(DataPackage::RegistryError)
      end

      it 'remote profile file does not exist' do
        registry_url = 'http://example.com/registry.json'
        profile_url = 'http://example.com/one.json'

        registry_body = [
          {
            'id'=> 'base',
            'title'=> 'Data Package',
            'schema'=> 'http://example.com/one.json',
            'schema_path'=> 'base.json',
            'specification'=> 'http://example.com'
          }
        ]

        FakeWeb.register_uri(:get, registry_url, :body => JSON.dump(registry_body))
        FakeWeb.register_uri(:get, profile_url, :body => "", :status => ["404", "Not Found"])

        registry = DataPackage::Registry.new(registry_url)

        expect { registry.get('base') }.to raise_error(DataPackage::RegistryError)
      end

      it 'local profile file does not exist' do

        registry_body = [
          {
            'id'=> 'base',
            'title'=> 'Data Package',
            'schema'=> 'http://example.com/one.json',
            'schema_path'=> 'inexistent.json',
            'specification'=> 'http://example.com'
          }
        ]

        profile_url = 'http://example.com/one.json'
        profile_body = '{ "title": "base_profile" }'

        FakeWeb.register_uri(:get, profile_url, :body => "", :status => ["404", "Not Found"])

        tempfile = Tempfile.new('.csv')
        tempfile.write(JSON.dump(registry_body))
        tempfile.rewind

        registry = DataPackage::Registry.new(tempfile.path)

        expect { registry.get('base') }.to raise_error(DataPackage::RegistryError)
      end

    end

    it 'returns nil if profile does not exist' do
      registry = DataPackage::Registry.new
      expect(registry.get('non-existent-profile')).to be_nil
    end

    it 'memoizes the profiles' do
      registry = DataPackage::Registry.new(@base_and_tabular_registry_path)

      base = registry.get('base')

      expect(registry).to_not receive(:get_profile).with('base')

      expect(registry.get('base')).to eq(base)
    end

  end

  context 'base path' do

    it 'defaults to the local cache path' do
      registry = DataPackage::Registry.new

      base_path = File.dirname(
        File.absolute_path(DataPackage::Registry::DEFAULT_REGISTRY_PATH)
      )

      expect(registry.base_path).to eq(base_path)
    end

    it 'uses received registry base path' do
      registry = DataPackage::Registry.new(@empty_registry_path)

      base_path = File.dirname(
        File.absolute_path(@empty_registry_path)
      )

      expect(registry.base_path).to eq(base_path)
    end

    it 'is none if registry is remote' do
      url = 'http://some-place.com/registry.csv'
      body = File.read(@base_registry_path)

      FakeWeb.register_uri(:get, url, :body => body)

      registry = DataPackage::Registry.new(url)

      expect(registry.base_path).to be_nil
    end

    it 'cannot be set' do
      registry = DataPackage::Registry.new

      expect { registry.base_path = "some/path" }.to raise_error(NoMethodError)
    end

  end

end
