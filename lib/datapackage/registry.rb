module DataPackage
  ##
  # Allow loading Data Package profiles from a registry.

  class Registry

    DEFAULT_REGISTRY_URL = 'http://schemas.datapackages.org/registry.csv'

    def initialize(registry_path_or_url = DEFAULT_REGISTRY_URL)
      @profiles = []
      @registry = get_registry(registry_path_or_url)
    end

    def get
    end

    def available_profiles
      @registry
    end

    private

      def base_path
      end

      def get_profile(profile_id)
      end

      def get_registry(registry_path_or_url)
        begin
          csv = CSV.new(open(registry_path_or_url), headers: :first_row, header_converters: :symbol)
          registry = csv.map {|row| { "#{row.fetch(:id)}" => row.to_h }  }.first
          raise(RegistryError) if registry.nil?
          registry
        rescue KeyError
          raise(RegistryError)
        end
      end

      def get_absolute_path(relative_path)
      end

      def load_json_file(path)
      end

      def load_json_url(url)
      end

  end
end
