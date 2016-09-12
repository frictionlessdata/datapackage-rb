module DataPackage
  class Schema < Hash

    attr_reader :schema

    def initialize(schema, options = {})
      @registry_url = options[:registry_url]
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

# https://gist.github.com/vdw/f3c832df8ce271a036f2
    def hash_to_slashed_path(hash, path = "")
      return {} unless hash
      hash.each_with_object({}) do |(k, v), ret|
        key = path + k.to_s

        if v.is_a? Hash
          ret.merge! hash_to_slashed_path(v, key.to_s + "/")
        else
          ret[key] = v
        end
      end
    end

    def dereference_schema path_or_url, schema
      paths = hash_to_slashed_path schema
      ref_keys = paths.keys.select { |p| p =~ /\$ref/ }
      if ref_keys
        ref_keys = [ref_keys] unless ref_keys.is_a? Array

        ref_keys.each do |key|
          path = key.split('/')[0..-2]

          replacement = resolve(schema.dig(*path, '$ref'), path_or_url, schema)

          s = "schema['properties']#{path.map { |k| "['#{k}']" }.join}.merge! replacement"
          eval s
          s = "schema['properties']#{path.map { |k| "['#{k}']" }.join}.delete '$ref'"
          eval s
        end
      end

      schema
    end

    def resolve reference, path_or_url, schema
      base_path = base_path path_or_url
      filename, reference = reference.split '#'
      filename = path_or_url.split('/')[-1] if filename == ''
      dereference_schema("#{base_path}/#{filename}", get_definitions(filename, base_path)).dig(*reference.split('/').reject(&:empty?))
    end

    def get_definitions filename, base_path
      JSON.parse open("#{base_path}/#{filename}").read
    end

    def base_path path_or_url
      if path_or_url =~ /\A#{URI::regexp}\z/
        uri = URI.parse path_or_url
        return "#{uri.scheme}://#{uri.host}#{File.dirname uri.path}".chomp('/')
      else

        if File.directory?(path_or_url)
          return path_or_url
        else
          return File.expand_path File.dirname path_or_url
        end
      end
    end

    def load_schema(path_or_url)
      json = open(path_or_url).read
      schema = JSON.parse json
      s = dereference_schema path_or_url, schema

    rescue OpenURI::HTTPError => e
      raise SchemaException.new "Schema URL returned #{e.message}"

    rescue JSON::ParserError
      raise SchemaException.new 'Schema is not valid JSON'

    rescue Errno::ENOENT
      raise SchemaException.new "Path '#{path_or_url}' does not exist"
    end

    def get_schema_from_registry schema
      d = DataPackage::Registry.new(@registry_url)
      dereference_schema (@registry_url || d.base_path), d.get(schema.to_s)
    end

    def validate(package)
      JSON::Validator.validate(self, package)
    end

    def valid?(package)
      validate(package) === true
    end

  end
end
