module DataPackage
  class Schema < Hash
    include DataPackage::Helpers
    attr_reader :schema

    def initialize(descriptor, options = {})
      @registry_url = options[:registry_url]
      @schema = get_schema(descriptor)
      self.merge!(@schema)
    rescue OpenURI::HTTPError, SocketError => e
      raise SchemaException.new "Schema URL returned #{e.message}"
    rescue JSON::ParserError
      raise SchemaException.new 'Schema is not valid JSON'
    rescue TypeError
      raise SchemaException.new 'Schema must be a URL, path, Hash or registry identifier'
    end

    def valid?(package)
      JSON::Validator.validate(self, package)
    end

    def validation_errors(package)
      JSON::Validator.fully_validate(self, package)
    end

    private

    def get_schema(descriptor)
      if descriptor.class == Hash
        descriptor
      else
        begin
          resolve_json_reference(descriptor)
        rescue Errno::ENOENT
          get_schema_from_registry(descriptor)
        end
      end
    end

    def get_schema_from_registry(descriptor)
      registry = DataPackage::Registry.new(@registry_url)
      schema = registry.get(descriptor)
      if schema.nil?
        raise SchemaException.new "Couldn't find registry entry by reference `#{descriptor}`"
      end
      schema
    end

  end
end
