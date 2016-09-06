module DataPackage
  class Schema < Hash

    attr_reader :schema

    def initialize(schema)
      if schema.class == Hash
        self.merge! schema
      elsif schema.class == Symbol
        self.merge! get_schema_from_registry schema
      else
        self.merge! load_schema(schema)
      end
    end

    def load_schema(path_or_url)
      json = open(path_or_url).read
      JSON.parse(json)

    rescue JSON::ParserError
      raise SchemaException.new 'Schema is not valid JSON'

    rescue Errno::ENOENT
      raise SchemaException.new "Path '#{path_or_url}' does not exist"
    end

    def get_schema_from_registry schema
      d = DataPackage::Registry.new
      d.get schema.to_s
    end
  end
end
