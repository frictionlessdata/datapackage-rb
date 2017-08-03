require 'open-uri'

module DataPackage
  class Package < Hash
    include DataPackage::Helpers

    attr_reader :opts, :errors, :profile
    attr_writer :resources

    # Parse or create a data package
    # Supports reading data from JSON file, directory, and a URL
    # descriptor:: Hash or String
    # opts:: Options used to customize reading and parsing
    def initialize(descriptor = nil, opts: {})
      @opts = opts
      @dead_resources = []
      self.merge! parse_package(descriptor)
      @profile = DataPackage::Profile.new(self.fetch('profile', 'data-package'))
      define_properties!
      load_resources!
    end

    def parse_package(descriptor)
      # TODO: base directory/url
      if descriptor.nil?
        {}
      elsif descriptor.class == Hash
        descriptor
      else
        read_package(descriptor)
      end
    end

    # Returns the directory for a local file package or base url for a remote
    # Returns nil for an in-memory object (because it has no base as yet)
    def base
      # user can override base
      return @opts[:base] if @opts[:base]
      return '' unless @location
      # work out base directory or uri
      if local?
          return File.dirname(@location)
      else
          return @location.split('/')[0..-2].join('/')
      end
    end

    # Is this a local package? Returns true if created from an in-memory object or a file/directory reference
    def local?
      return @local if @local
      return false if @location =~ /\A#{URI::regexp}\z/
      true
    end

    def resources
      update_resources!
      @resources
    end

    def property(property, default = nil)
      self[property] || default
    end

    def valid?
      validate
      @valid
    end

    def validate
      @errors = @profile.validate(self)
      @valid = @profile.valid?(self)
    end

    def resource_exists?(location)
      @dead_resources.include?(location)
    end

    def to_json
      self.to_json
    end

    private

    def define_properties!
      (@profile['properties'] || {}).each do |k, v|
        next if k == 'resources' || k == 'profile'
        define_singleton_method("#{k.to_sym}=", proc { |p| set_property(k, p) })
        define_singleton_method(k.to_sym.to_s, proc { property k, default_value(v) })
      end
    end

    def load_resources!
      @resources = (self['resources'] || [])
      update_resources!
    end

    def update_resources!
      @resources.map! do |resource|
        begin
          load_resource(resource)
        rescue ResourceException
          @dead_resources << resource['path']
          nil
        end
      end
    end

    def load_resource(resource)
      if resource.is_a?(Resource)
        resource
      else
        Resource.new(resource, base)
      end
    end

    def default_value(profile_data)
      case profile_data['type']
      when 'string'
          nil
      when 'array'
          []
      when 'object'
          {}
      end
    end

    def set_property(key, value)
      self[key] = value
    end

    def read_package(descriptor)
      if File.extname(descriptor) == '.zip'
        unzip_package(descriptor)
      else
        default_filename = @opts[:default_filename] || 'datapackage.json'
        descriptor = join_paths(descriptor, default_filename)
        @location = descriptor.to_s
        load_json(descriptor)
      end
    end

    def unzip_package(descriptor)
      descriptor = write_to_tempfile(descriptor) if descriptor =~ /\A#{URI::regexp}\z/
      dir = Dir.mktmpdir
      package = {}
      Zip::File.open(descriptor) do |zip_file|
          # Extract all the files
          zip_file.each { |entry| entry.extract("#{dir}/#{File.basename entry.name}") }
          # Get and parse the datapackage metadata
          entry = zip_file.glob("*/#{@opts[:default_filename] || 'datapackage.json'}").first
          package = JSON.parse(entry.get_input_stream.read)
      end
      # Set the base dir to the directory we unzipped to
      @opts[:base] = dir
      # This is now a local file, not a URL
      @local = true
      package
    end

    def write_to_tempfile(url)
      tempfile = Tempfile.new('datapackage')
      tempfile.write(open(url).read)
      tempfile.rewind
      tempfile
    end
  end
end
