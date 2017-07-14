require 'open-uri'

module DataPackage
  class Package < Hash
    attr_reader :opts, :errors
    attr_writer :resources

    # Parse or create a data package
    #
    # Supports reading data from JSON file, directory, and a URL
    #
    # package:: Hash or a String
    # schema:: Hash, Symbol or String
    # opts:: Options used to customize reading and parsing
    def initialize(package = nil, schema = 'data-package', opts = {})
      @opts = opts
      @schema = DataPackage::Schema.new(schema || 'data-package')
      @dead_resources = []

      self.merge! parse_package(package)
      define_properties!
      load_resources!
    end

    def parse_package(package)
      # TODO: base directory/url
      if package.nil?
        {}
      elsif package.class == Hash
        package
      else
        read_package(package)
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
      return !@location.start_with?('http') if @location
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
      @errors = @schema.validation_errors(self)
      @valid = @schema.valid?(self)
    end

    def resource_exists?(location)
      @dead_resources.include?(location)
    end

    def to_json
      self.to_json
    end

    private

    def define_properties!
      (@schema['properties'] || {}).each do |k, v|
        next if k == 'resources'
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
        rescue
          @dead_resources << resource['path']
          nil
        end
      end
    end

    def load_resource(resource)
      if resource.is_a?(Resource)
        resource
      else
        Resource.load(resource, base)
      end
    end

    def default_value(schema_data)
      case schema_data['type']
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

    def read_package(package)
      if is_directory?(package)
          package = File.join(package, opts[:default_filename] || 'datapackage.json')
      elsif is_containing_url?(package)
          package = URI.join(package, 'datapackage.json')
      end

      @location = package.to_s

      if File.extname(package.to_s) == '.zip'
          unzip_package(package)
      else
          JSON.parse open(package).read
      end
    end

    def is_directory?(package)
      !package.start_with?('http') && File.directory?(package)
    end

    def is_containing_url?(package)
      package.start_with?('http') && !package.end_with?('datapackage.json', 'datapackage.zip')
    end

    def write_to_tempfile(url)
      tempfile = Tempfile.new('datapackage')
      tempfile.write(open(url).read)
      tempfile.rewind
      tempfile
    end

    def unzip_package(package)
      package = write_to_tempfile(package) if package.start_with?('http')
      dir = Dir.mktmpdir
      Zip::File.open(package) do |zip_file|
          # Extract all the files
          zip_file.each { |entry| entry.extract("#{dir}/#{File.basename entry.name}") }
          # Get and parse the datapackage metadata
          entry = zip_file.glob("*/#{opts[:default_filename] || 'datapackage.json'}").first
          package = JSON.parse(entry.get_input_stream.read)
      end
      # Set the base dir to the directory we unzipped to
      @opts[:base] = dir
      # This is now a local file, not a URL
      @local = true
      package
    end
  end
end
