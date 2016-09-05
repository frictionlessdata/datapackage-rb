module DataPackage
  ##
  # Allow loading Data Package profiles from a registry.

  class Registry

    def initialize(registry_path_or_url)
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
        csv = CSV.new(open(registry_path_or_url), headers: :first_row, header_converters: :symbol)
        registry = csv.map {|row| { "#{row[:id]}" => row.to_h }  }.first
        registry
      end

      def get_absolute_path(relative_path)
      end

      def load_json_file(path)
      end

      def load_json_url(url)
      end

  end
end
