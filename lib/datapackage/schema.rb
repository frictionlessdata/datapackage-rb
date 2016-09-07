module DataPackage
  class Schema < Hash

    attr_reader :schema

    def initialize(schema)
      if schema.class == Hash
        self.merge! schema
      elsif schema.class == Symbol
        self.merge! get_schema_from_registry schema
      elsif schema.class == String
        self.merge! load_schema(schema)
      else
        raise SchemaException.new "Schema must be a URL, path, Hash or registry-identifier"
      end
    end

    def dereference_schema(path_or_url, schema)
      base_path = File.expand_path File.dirname path_or_url
      schema['properties'].each_pair.map do |k,v|
        if v['$ref']
          filename, reference = v.delete('$ref').split('#')
          # load the reference
          definitions = JSON.parse(File.read(base_path + '/' + filename))
          defs = definitions.dig *reference.split('/').reject(&:empty?)
          # replace the ref with the thing
          v.merge!(defs)
        else
          v
        end
      end
      schema
    end

    def load_schema(path_or_url)
      json = open(path_or_url).read
      schema = JSON.parse(json)
      dereference_schema(path_or_url, schema)

    rescue OpenURI::HTTPError => e
      raise SchemaException.new "Schema URL returned #{e.message}"

    rescue JSON::ParserError
      raise SchemaException.new 'Schema is not valid JSON'

    rescue Errno::ENOENT
      raise SchemaException.new "Path '#{path_or_url}' does not exist"
    end

    def get_schema_from_registry schema
      d = DataPackage::Registry.new
      d.get schema.to_s
    end

    def validate(package)
      JSON::Validator.validate(self, package)
    end

    def valid?(package)
      validate(package) === true
    end

  end
end
