module DataPackage
  # Allow loading Data Package profiles from the official registry.

  class Registry
    include DataPackage::Helpers

    attr_reader :path, :profiles

    DEFAULT_REGISTRY_URL = 'https://specs.frictionlessdata.io/schemas/registry.json'.freeze
    DEFAULT_REGISTRY_PATH = File.join(File.expand_path(File.dirname(__FILE__)), '..', 'profiles', 'registry.json').freeze

    def initialize
      @path = DEFAULT_REGISTRY_PATH
      @profiles = get_registry(DEFAULT_REGISTRY_PATH)
    rescue Errno::ENOENT
      raise RegistryException.new 'Registry path is not valid'
    rescue OpenURI::HTTPError, SocketError => e
      raise RegistryException.new "Registry URL returned #{e.message}"
    rescue JSON::ParserError
      raise RegistryException.new 'Registry descriptor is not valid JSON'
    rescue KeyError
      raise RegistryException.new 'Property `id` is mandatory for profiles'
    end

    private

    def get_registry(descriptor)
      resources = load_json(descriptor)
      resources.reduce({}) do |registry, resource|
        registry[resource['id']] = resource
        registry
      end
    end

  end
end
