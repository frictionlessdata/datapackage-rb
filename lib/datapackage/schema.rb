module DataPackage
  class Schema < Hash

    attr_reader :schema

    def initialize(schema)
      if schema.class == Hash
        self.merge! schema
      else
        self.merge! load_schema(schema)
      end
    end

    def load_schema(path_or_url)
      json = open(path_or_url).read
      JSON.parse(json)
    end

  end
end
