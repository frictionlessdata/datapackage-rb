require 'spec_helper'

describe DataPackage::Registry do

  before(:each) do
    @base_registry_path = File.join('spec', 'fixtures', 'base_registry.json')
    @empty_registry_path = File.join('spec', 'fixtures', 'empty_registry.json')
    @base_and_tabular_registry_path = File.join('spec', 'fixtures', 'base_and_tabular_registry.json')
    @unicode_registry_path = File.join('spec', 'fixtures', 'unicode_registry.json')
    @base_profile_path = File.join('spec', 'fixtures', 'base_profile.json')
  end

  it 'has a default registry url' do
    expect(DataPackage::Registry.new.path).to_not be_nil
    expect(DataPackage::Registry.new.path).to_not be_empty
  end

  context 'profiles' do

    it 'returns list of profiles' do
      registry = DataPackage::Registry.new

      expect(registry.profiles).to_not be_empty
      expect(registry.profiles['tabular-data-package'].keys).to include(
          'id',
          'schema',
          'schema_path',
      )
    end

    it 'cannot be set' do
      expect { DataPackage::Registry.new.profiles = {} }.to raise_error(NoMethodError)
    end

    it 'returns nil when profile is not found' do
      expect(DataPackage::Registry.new.profiles['no-such-profile']).to be_nil
    end

  end

  context 'path' do

    it 'defaults to the local cache path' do
      expect(DataPackage::Registry.new.path).to eq(DataPackage::Registry::DEFAULT_REGISTRY_PATH)
    end

    it 'cannot be set' do
      expect { DataPackage::Registry.new.path = "some/path" }.to raise_error(NoMethodError)
    end

  end

end
