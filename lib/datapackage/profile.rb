module DataPackage
  class Profile < Hash
    include DataPackage::Helpers

    attr_reader :name, :registry

    def initialize(descriptor)
      unless descriptor.is_a?(String)
        raise ProfileException.new 'Profile must be a URL or registry identifier'
      end
      @name = descriptor
      if is_fully_qualified_url?(descriptor)
        self.merge!(load_json(descriptor))
      else
        self.merge!(get_profile_from_registry(descriptor))
      end
    rescue OpenURI::HTTPError, SocketError => e
      raise ProfileException.new "Profile URL returned #{e.message}"
    rescue JSON::ParserError
      raise ProfileException.new 'Profile is not valid JSON'
    end

    def jsonschema
      self.to_h
    end

    # Returns true if there are no errors, false if there are
    def valid?(package)
      JSON::Validator.validate(self, package)
    end

    # Returns an array of validation errors
    def validate(package)
      JSON::Validator.fully_validate(self, package)
    end

    private

    def get_profile_from_registry(descriptor)
      @registry = DataPackage::Registry.new
      profile_metadata = registry.profiles.fetch(descriptor)
      if profile_metadata.fetch('schema_path', nil)
        profile_path = join_paths(base_path(registry.path), profile_metadata['schema_path'])
      else
        profile_path = profile_metadata['schema']
      end
      load_json(profile_path)
    rescue KeyError
      raise ProfileException.new "Couldn't find profile with id `#{descriptor}` in registry"
    end

  end
end
