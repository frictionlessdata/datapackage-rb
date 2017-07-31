module DataPackage
  class Resource < Hash
    include DataPackage::Helpers
    attr_reader :data

    def initialize(resource, base_path = '')
      resource = dereference_descriptor(resource, base_path: base_path,
        reference_fields: ['schema', 'dialect'])
      if resource.fetch('data', nil)
        @data = resource['data']
      elsif resource.fetch('path', nil)
        @data = open(join_paths(base_path, resource['path'])).read
      else
        raise ResourceError.new 'A resource descriptor must have a `path` or `data` property.'
      end
      self.merge! resource
    end

    def table
      @table ||= JsonTableSchema::Table.new(CSV.parse(data), self['schema']) if self['schema']
    end

  end
end
