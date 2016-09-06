describe DataPackage::Schema do

  context 'initialize' do

    it 'loads a schema from a hash' do
      schema_hash = {
        foo: 'bar'
      }
      schema = DataPackage::Schema.new(schema_hash)

      expect(schema.schema).to eq(schema_hash)
      expect(schema.schema['foo']).to eq(schema_hash['foo'])
    end

    it 'loads a schema from a path' do
      path = File.join('spec', 'fixtures', 'empty_schema.json')

      schema = DataPackage::Schema.new(path)

      expect(schema.schema).to eq({})
    end

    it 'loads a schema from a url' do
      url = 'http://example.org/thing.json'
      body = File.read File.join('spec', 'fixtures', 'empty_schema.json')

      FakeWeb.register_uri(:get, url, :body => body)

      schema = DataPackage::Schema.new(url)

      expect(schema.schema).to eq({})
    end

    it 'loads a schema from the registry'

    context 'raises an error' do

      it 'when the path does not exist'

      it 'when the path is no json'

      it 'when the url is not json'

      it 'when the url does not exist'

      it 'when the schema is not a string or hash'

      it 'when the schema is invalid'

    end

  end

  context 'validate' do

    it 'validates correctly'

    it 'returns errors'

    it 'returns multiple errors'
    # test_iter_validation_returns_iter_with_each_validationerror

    it 'retuns no errors if data is valid'

  end

  it 'creates attributes for every toplevel attribute'

  it 'does not allow changing schema properties'

  it 'allows changing properties not in schema'

  it ' does not change the originals when changing properties'

end

#
# def test_to_dict_converts_schema_to_dict(self):
#     original_schema_dict = {
#         'foo': 'bar',
#     }
#     schema = Schema(original_schema_dict)
#     assert schema.to_dict() == original_schema_dict
#
# def test_to_dict_modifying_the_dict_doesnt_modify_the_schema(self):
#     original_schema_dict = {
#         'foo': 'bar',
#     }
#     schema = Schema(original_schema_dict)
#     schema_dict = schema.to_dict()
#     schema_dict['bar'] = 'baz'
#     assert 'bar' not in schema.to_dict()
# def test_properties_are_visible_with_dir(self):
#     schema_dict = {
#         'foo': {}
#     }
#     schema = Schema(schema_dict)
#     assert 'foo' in dir(schema)
#
#
# def test_schema_properties_doesnt_linger_in_class(self):
#     foo_schema_dict = {
#         'foo': {}
#     }
#     bar_schema_dict = {
#         'bar': {}
#     }
#     foo_schema = Schema(foo_schema_dict)
#     bar_schema = Schema(bar_schema_dict)
#
#     assert 'bar' not in dir(foo_schema)
#     assert 'foo' not in dir(bar_schema)
#
