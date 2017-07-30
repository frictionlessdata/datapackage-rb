module DataPackage
  class Schema < Hash
    include DataPackage::Helpers
    attr_reader :schema

    def initialize(schema, options = {})
      @registry_url = options[:registry_url]
      @schema = get_schema(schema)
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

    def get_schema(schema_reference)
      if schema_reference.class == Hash
        schema_reference
      else
        begin
          resolve_reference(schema_reference)
        rescue Errno::ENOENT
          get_schema_from_registry(schema_reference)
        end
      end
    end

    def get_schema_from_registry(schema_reference)
      registry = DataPackage::Registry.new(@registry_url)
      schema = registry.get(schema_reference)
      if schema.nil?
        raise SchemaException.new "Couldn't find registry entry by reference `#{schema_reference}`"
      end
      schema
    end

  end
end
