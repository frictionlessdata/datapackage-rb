require 'open-uri'

module DataPackage
  class Package < Hash
    include DataPackage::Helpers

    # Public

    attr_reader :errors, :profile

    # Parse or create a data package
    # Supports reading data from JSON file, directory, and a URL
    # descriptor:: Hash or String
    # opts:: Options used to customize reading and parsing
    def initialize(descriptor = nil, opts: {})
      @opts = opts
      @dead_resources = []
      self.merge! parse_package(descriptor)
      @profile = DataPackage::Profile.new(self.fetch('profile', DataPackage::DEFAULTS[:package][:profile]))
      self['profile'] = @profile.name
      define_properties!
      load_resources!
    rescue OpenURI::HTTPError, SocketError => e
      raise PackageException.new "Package URL returned #{e.message}"
    rescue JSON::ParserError
      raise PackageException.new 'Package descriptor is not valid JSON'
    end

    def valid?
      return false unless @profile.valid?(self)
      return false if self['resources'].map{ |resource| resource.valid? }.include?(false)
      true
    end

    alias :valid  :valid?

    def validate
      @profile.validate(self)
      self['resources'].each { |resource| resource.validate }
      true
    end

    def iter_errors
      errors = @profile.iter_errors(self){ |err| err }
      self['resources'].each do |resource|
        resource.iter_errors{ |err| errors << err }
      end
      errors.each{ |error| yield error }
    end

    def descriptor
      self.to_h
    end

    def resources
      update_resources!
      self['resources']
    end

    def resource_names
      update_resources!
      self['resources'].map{|res| res.name}
    end

    def get_resource(resource_name)
      update_resources!
      self['resources'].find{ |resource| resource.name == resource_name }
    end

    def add_resource(resource)
      resource = load_resource(resource)
      self['resources'].push(resource)
      begin
        self.validate
        resource
      rescue DataPackage::ValidationError
        self['resources'].pop
        nil
      end
    end

    def remove_resource(resource_name)
      update_resources!
      resource = get_resource(resource_name)
      self['resources'].reject!{ |resource| resource.name == resource_name }
      resource
    end

    def save(target=@location)
      update_resources!
      File.open(target, "w") { |file| file << JSON.pretty_generate(self) }
      true
    end

    # Deprecated

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

    def property(property, default = nil)
      self[property] || default
    end

    def infer(base_path: nil, directory: nil)
      raise PackageException.new('Base path is required for infer') unless base_path
      raise PackageException.new('Directory is required for infer') unless directory

      dir_path = File.join(base_path, directory)
      Dir.glob("#{dir_path}/*.csv") do |filename|
        resource = Resource.infer(filename)
        add_resource(resource)
      end
      descriptor
    end

    # Private

    private

    def define_properties!
      (@profile['properties'] || {}).each do |k, v|
        next if k == 'resources' || k == 'profile'
        define_singleton_method("#{k.to_sym}=", proc { |p| set_property(k, p) })
        define_singleton_method(k.to_sym.to_s, proc { property k, default_value(v) })
      end
    end

    def load_resources!
      self['resources'] ||= []
      update_resources!
    end

    def update_resources!
      self['resources'].map! do |resource|
        begin
          load_resource(resource)
        rescue ResourceException
          @dead_resources << resource
          nil
        end
      end.compact!
    end

    def load_resource(resource)
      if resource.is_a?(Resource)
        resource
      else
        Resource.new(resource, base)
      end
    end

    def default_value(field_data)
      case field_data['type']
      when 'array'
          []
      when 'object'
          {}
      else
        nil
      end
    end

    def set_property(key, value)
      self[key] = value
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

    def read_package(descriptor)
      if File.extname(descriptor) == '.zip'
        unzip_package(descriptor)
      else
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
