module DataPackage
  class Schema

    attr_reader :schema

    def initialize(schema)
      if schema.class == Hash
        @schema = schema
      else
        @schema = load_schema(schema)
      end
    end

    def load_schema(path_or_url)
      json = open(path_or_url).read
      JSON.parse(json)
    end

  end
end
