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
          csv = parse_csv(registry_path_or_url)
          registry = {}
          csv.each { |row| registry[row.fetch(:id)] = row.to_h } 
        rescue KeyError, OpenURI::HTTPError, Errno::ENOENT
          raise(RegistryError)
        end
        registry
      end

      def parse_csv(path_or_url)
        csv = open(path_or_url).read
        if csv.match(/,/)
          CSV.new(csv, headers: :first_row, header_converters: :symbol)
        else
          raise RegistryError
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
