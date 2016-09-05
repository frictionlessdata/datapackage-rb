require 'spec_helper'

describe DataPackage::Registry do

  it 'accepts urls' do
    pending
  end

  context 'raises an error' do

    it 'if registry is not a CSV' do
      pending
    end

    it 'if registry has no ID field' do
      pending
    end

    it 'if registry webserver raises error' do
      pending
    end

    it 'registry path does not exist' do
      pending
    end


  end

  it 'has a default registry url' do
    pending
  end

  context 'available profiles' do

    it 'available profiles returns empty array when registry is empty' do
      pending
    end

    it 'returns list of profiles' do
      pending
    end

    it 'cannot be set' do
      pending
    end

    it 'works with unicode strings' do
      pending
    end

  end

  context 'get' do

    it 'loads profile from disk' do
      pending
    end

    it 'loads remote file if local copy does not exist' do
      pending
    end

    context 'raises an error' do

      it 'if profile is not json' do
        pending
      end

      it 'remote profile file does not exist' do
        pending
      end

      it 'local profile file does not exist' do
        pending
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
