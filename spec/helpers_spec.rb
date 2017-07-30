require 'spec_helper'

describe DataPackage::Helpers do

  include DataPackage::Helpers

  context 'dereference_resource' do
    it 'doesn\'t change non-referencial values' do
      hash = {'string': 'string', 'integer': 6}

      expect(dereference_resource(hash)).to eq(hash)
    end

    it 'dereferences pointers' do
      hash = {
        'resources'=> [{'fields'=>{'$ref'=> '#schemas/main/fields'}}],
        'schemas'=> {
          'main'=> {
            'fields'=> [{'name'=> 'name'}]
          }
        }
      }
      expect(dereference_resource(hash)).to eq({
        'resources'=> [{'fields'=> [{'name'=> 'name'}]}],
        'schemas'=> {
          'main'=> {
            'fields'=> [{'name'=> 'name'}]
          }
        }
      })
    end

    it 'dereferences URLs' do
      url = 'http://example.org/thing.json'
      nested_url = 'http://example.org/nested_thing.json'
      nested_body = {'nested_attr'=> 3}
      body = {'ref_to_nested_url'=> nested_url}

      FakeWeb.register_uri(:get, nested_url, :body => JSON.dump(nested_body))
      FakeWeb.register_uri(:get, url, :body => JSON.dump(body))

      expect(dereference_resource(url)).to eq({
        'ref_to_nested_url'=> {
          'nested_attr'=> 3
        }
      })
    end

  end
end
