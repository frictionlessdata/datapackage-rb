require 'spec_helper'

describe DataPackage::Helpers do

  include DataPackage::Helpers

  context 'dereference_descriptor' do
    it 'doesn\'t change non-referencial values' do
      hash = {'string'=> 'string', 'integer'=> 6}

      expect(dereference_descriptor(hash)).to eq(hash)
    end

    xit 'dereferences URLs' do
      url = 'http://example.org/thing.json'
      nested_url = 'http://example.org/nested_thing.json'
      nested_body = {'nested_attr'=> 3}
      body = {'ref_to_nested_url'=> nested_url}

      FakeWeb.register_uri(:get, nested_url, :body => JSON.dump(nested_body))
      FakeWeb.register_uri(:get, url, :body => JSON.dump(body))

      expect(dereference_descriptor(url)).to eq({
        'ref_to_nested_url'=> {
          'nested_attr'=> 3
        }
      })
    end

    it 'dereferences paths' do
      filepath = File.join( File.dirname(__FILE__), 'fixtures', 'base_profile.json' )

      expect(dereference_descriptor(filepath)).to eq({
        'title'=> 'base_profile'
      })
    end

    it 'dereferences paths with base_path' do
      filename = 'base_profile.json'
      base_path = File.join( File.dirname(__FILE__), 'fixtures')

      expect(dereference_descriptor(filename, base_path: base_path)).to eq({
        'title'=> 'base_profile'
      })
    end

    it 'dereferences nested reference' do
      filename = 'base_profile.json'
      base_path = File.join( File.dirname(__FILE__), 'fixtures')
      descriptor = {
        'resources'=> [
          {
            'resource_attrs'=> filename
          }
        ]
      }

      expect(dereference_descriptor(descriptor, base_path: base_path)).to eq({
        'resources' => [
          {
            'resource_attrs' => {
              'title'=> 'base_profile'
            }
          }
        ]
      })
    end

    xit 'dereferences only reference_fields if present' do
      schema_url = 'http://example.org/schema.json'
      random_url = 'http://example.org/random.json'
      schema_body = {'fields'=> [{'name'=>'Price', 'title'=>'Price', 'type'=>'integer'}]}
      random_body = {'field_name'=> 3}
      descriptor = {
        'schema'=> schema_url,
        'random'=> random_url,
      }

      FakeWeb.register_uri(:get, schema_url, :body => JSON.dump(schema_body))
      FakeWeb.register_uri(:get, random_url, :body => JSON.dump(random_body))

      expect(dereference_descriptor(descriptor, reference_fields: ['schema'])).to eq({
        'schema'=> {
          'fields' => [{'name'=>'Price', 'title'=>'Price', 'type'=>'integer'}]
        },
        'random'=> random_url
      })
    end

  end

  context 'is_fully_qualified_url' do

    it 'is true for a fully qualified HTTP/HTTPS URL' do
      expect(is_fully_qualified_url?('http://example.org/schema.json')).to be true
    end

    it 'is false for non-URI strings' do
      expect(is_fully_qualified_url?('def not an URI')).to be false
    end

    it 'is false for URI strings if they are not HTTP(S)' do
      expect(is_fully_qualified_url?('ftp://example.org/schema.json')).to be false
    end

  end

  context 'is_safe_path' do

    it 'is true for a relative path' do
      expect(is_safe_path?('test-pkg/test.csv')).to be true
    end

    it 'is false for an absolute path' do
      expect(is_safe_path?('/test.csv')).to be false
    end

    it 'is false for a parent relative path' do
      expect(is_safe_path?('../fixtures/test-pkg/test.csv')).to be false
    end
  end

end
