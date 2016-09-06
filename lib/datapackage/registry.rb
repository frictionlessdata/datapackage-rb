module DataPackage
  ##
  # Allow loading Data Package profiles from a registry.

  class Registry

    DEFAULT_REGISTRY_URL = 'http://schemas.datapackages.org/registry.csv'

    def initialize(registry_path_or_url = DEFAULT_REGISTRY_URL)
      if File.file?(registry_path_or_url)
        @base_path = File.dirname(
          File.absolute_path(registry_path_or_url)
        )
      end
      @profiles = {}
      @registry = get_registry(registry_path_or_url)
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

        path = get_absolute_path(profile_metadata[:schema_path])

        if path && File.file?(path)
          load_json(path)
        else
          url = profile_metadata[:schema]
          load_json(url)
        end
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
        File.join(@base_path, relative_path)
      rescue TypeError
        nil
      end

      def load_json(path)
        json = open(path).read
        JSON.parse(json)
      rescue JSON::ParserError, OpenURI::HTTPError
        raise RegistryError
      end

  end
end
