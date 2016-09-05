require 'spec_helper'

describe DataPackage::Registry do

  before(:each) do
    @base_registry_path = File.join('spec', 'fixtures', 'base_registry.csv')
    @empty_registry_path = File.join('spec', 'fixtures', 'empty_registry.csv')
    @base_and_tabular_registry_path = File.join('spec', 'fixtures', 'base_and_tabular_registry.csv')
    @unicode_registry_path = File.join('spec', 'fixtures', 'unicode_registry.csv')
    @base_profile_path = File.join('spec', 'fixtures', 'base_profile.json')
  end

  context 'initialize' do

    before(:each) do
      @url = 'http://some-place.com/registry.csv'
      @body = File.read(@base_registry_path)
    end

    it 'accepts urls' do
      FakeWeb.register_uri(:get, @url, :body => @body)

      registry = DataPackage::Registry.new(@url)

      expect(registry.available_profiles.values.count).to eq(1)
      expect(registry.available_profiles['base']).to eq({
          id: 'base',
          title: 'Data Package',
          schema: 'http://example.com/one.json',
          specification: 'http://example.com'
      })
    end

    it 'has a default registry url' do
      default_url = 'http://schemas.datapackages.org/registry.csv'

      FakeWeb.register_uri(:get, default_url, :body => @body)

      registry = DataPackage::Registry.new()

      expect(registry.available_profiles.values.count).to eq(1)
    end

    it 'accepts a path' do
      registry = DataPackage::Registry.new(@base_registry_path)

      expect(registry.available_profiles.values.count).to eq(1)
      expect(registry.available_profiles['base']).to eq({
          id: 'base',
          title: 'Data Package',
          schema: 'http://example.com/one.json',
          specification: 'http://example.com'
      })
    end

  end

  context 'raises an error' do

    it 'if registry is not a CSV' do
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
          id: 'base',
          title: 'Data Package',
          schema: 'http://example.com/one.json',
          schema_path: 'base_profile.json',
          specification: 'http://example.com'
      })
      expect(registry.available_profiles['tabular']).to eq({
          id: 'tabular',
          title: 'Tabular Data Package',
          schema: 'http://example.com/two.json',
          schema_path: 'tabular_profile.json',
          specification: 'http://example.com'
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
      expect(base_profile_metadata[:title]).to eq('Iñtërnâtiônàlizætiøn')
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
      body = [
        'id,title,schema,specification,schema_path',
        'base,Data Package,http://example.com/one.json,http://example.com,inexistent.json'
      ].join("\r\n")

      profile_url = 'http://example.com/one.json'
      profile_body = '{ "title": "base_profile" }'

      FakeWeb.register_uri(:get, profile_url, :body => profile_body)

      tempfile = Tempfile.new('.csv')
      tempfile.write(body)
      tempfile.rewind

      registry = DataPackage::Registry.new(tempfile.path)

      base_profile = registry.get('base')
      expect(base_profile).to_not eq(nil)
      expect(base_profile['title']).to eq('base_profile')
    end

    context 'raises an error' do

      it 'if profile is not json' do
        registry_path = File.join('spec', 'fixtures', 'registry_with_notajson_profile.csv')
        registry = DataPackage::Registry.new(registry_path)

        expect { registry.get('notajson') }.to raise_error(DataPackage::RegistryError)
      end

      it 'remote profile file does not exist' do
        registry_url = 'http://example.com/registry.csv'
        profile_url = 'http://example.com/one.json'

        registry_body = [
          'id,title,schema,specification,schema_path',
          'base,Data Package,http://example.com/one.json,http://example.com,base.json'
        ].join("\r\n")

        FakeWeb.register_uri(:get, registry_url, :body => registry_body)
        FakeWeb.register_uri(:get, profile_url, :body => "", :status => ["404", "Not Found"])

        registry = DataPackage::Registry.new(registry_url)

        expect { registry.get('base') }.to raise_error(DataPackage::RegistryError)
      end

      it 'local profile file does not exist' do
        body = [
          'id,title,schema,specification,schema_path',
          'base,Data Package,http://example.com/one.json,http://example.com,inexistent.json'
        ].join("\r\n")

        profile_url = 'http://example.com/one.json'
        profile_body = '{ "title": "base_profile" }'

        FakeWeb.register_uri(:get, profile_url, :body => "", :status => ["404", "Not Found"])

        tempfile = Tempfile.new('.csv')
        tempfile.write(body)
        tempfile.rewind

        registry = DataPackage::Registry.new(tempfile.path)

        expect { registry.get('base') }.to raise_error(DataPackage::RegistryError)
      end

    end

    it 'returns nil if profile does not exist' do
      pending
    end

    it 'memoizes the profiles' do
      pending
    end

  end

  context 'base path' do

    it 'defaults to the local cache path' do
      pending
    end

    it 'uses received registry base path' do
      pending
    end

    it 'is none if registry is remote' do
      pending
    end

    it 'cannot be set' do
      pending
    end

  end

end
