module DataPackage
  # Allow loading Data Package profiles from a registry.

  class Registry
    include DataPackage::Helpers
    attr_reader :base_path

    DEFAULT_REGISTRY_URL = 'https://specs.frictionlessdata.io/schemas/registry.json'
    DEFAULT_REGISTRY_PATH = File.join(File.expand_path(File.dirname(__FILE__)), '..', 'profiles', 'registry.json')

    def initialize(descriptor = DEFAULT_REGISTRY_PATH)
      descriptor ||= DEFAULT_REGISTRY_PATH
      if File.file?(descriptor)
        @base_path = File.dirname(
          File.absolute_path(descriptor)
        )
      end
      @profiles = {}
      @registry = get_registry(descriptor)
      self
    rescue Errno::ENOENT
      raise RegistryError.new 'Registry path is not valid'
    rescue OpenURI::HTTPError, SocketError => e
      raise RegistryError.new "Registry URL returned #{e.message}"
    rescue JSON::ParserError
      raise RegistryError.new 'Registry descriptor is not valid JSON'
    rescue KeyError
      raise RegistryError.new 'Property `id` is mandatory for profiles'
    end

    def get(profile_id)
      @profiles[profile_id] ||= get_profile(profile_id)
    end

    def available_profiles
      @registry
    end

    private

      def get_profile(profile_id)
        profile_metadata = @registry[profile_id]
        return if profile_metadata.nil?

        path = get_absolute_path(profile_metadata['schema_path'])

        if path && File.file?(path)
          load_json(path)
        else
          url = profile_metadata['schema']
          load_json(url)
        end
      rescue Errno::ENOENT
        raise RegistryError.new 'Profile path is not valid'
      rescue OpenURI::HTTPError, SocketError => e
        raise RegistryError.new "Profile URL returned #{e.message}"
      rescue JSON::ParserError
        raise RegistryError.new 'Profile descriptor is not valid JSON'
      end

      def get_registry(descriptor)
        resources = resolve_json_reference(descriptor)
        resources.reduce({}) do |registry, resource|
          registry[resource['id']] = resource
          registry
        end
      end

      def get_absolute_path(relative_path)
        File.join(@base_path, relative_path)
      rescue TypeError
        nil
      end

  end
end
