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
      @base_path = base_path path_or_url

      paths = hash_to_slashed_path schema['properties']

      ref_keys = paths.keys.find { |p| p =~ /\$ref/ }
      if ref_keys
        ref_keys = [ref_keys] unless ref_keys.is_a? Array

        ref_keys.each do |key|
          path = key.split('/')[0..-2]
          replacement = resolve(schema['properties'].dig(*path, '$ref'))

          until path.count == 1
            schema['properties'] = schema['properties'][path.shift]
          end
          last_path = path.shift
          schema['properties'][last_path].merge! replacement
          schema['properties'][last_path].delete '$ref'
        end
      end
      #schema['properties'] = walk schema['properties']

    #  (schema['properties'] || {}).each_pair.map do |k, v|
    #    if v['$ref']
    #      v.merge! resolve(v['$ref'])
    #      v.delete '$ref'
    #    elsif v.is_a? Hash
    #      require "pry" ; binding.pry
    #      dereference_schema path_or_url, v
    #    else
    #      v
    #    end
    #  end

      schema
    end

    def resolve reference
      filename, reference = reference.split '#'
      get_definitions(filename).dig *reference.split('/').reject(&:empty?)
    end

    def walk tree
      resolved = {}

      tree.each_pair.map do |k, v|
        if k == '$ref'
          resolved = resolve(v)
          puts "------------------------------------------------------"
          puts "I resolved this: #{resolved}"
          puts tree
        #  tree.merge! resolved

        end
#tree.delete '$ref'
        if v.is_a? Hash
          walk v
        end
      end
    end

    def get_definitions filename
      JSON.parse open("#{@base_path}/#{filename}").read
    end

    def base_path path_or_url
      if path_or_url =~ /\A#{URI::regexp}\z/
        uri = URI.parse path_or_url
        return "#{uri.scheme}://#{uri.host}#{File.dirname uri.path}".chomp('/')
      else
        return File.expand_path File.dirname path_or_url
      end
    end

    def load_schema(path_or_url)
      json = open(path_or_url).read
      schema = JSON.parse json
      dereference_schema path_or_url, schema

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
