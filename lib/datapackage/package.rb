require 'open-uri'

module DataPackage

    class Package

        attr_reader :metadata, :opts

        # Parse or create a data package
        #
        # Supports reading data from JSON file, directory, and a URL
        #
        # package:: Hash or a String
        # opts:: Options used to customize reading and parsing
        def initialize(package = nil, opts={})
          @opts = opts
          @schema = DataPackage::Schema.new(opts[:schema] || :base)
          @metadata = parse_package(package)
          define_properties!
        end

        def parse_package(package)
          #TODO base directory/url
          if package == nil
            {}
          elsif package.class == Hash
            package
          else
            if !package.start_with?("http") && File.directory?(package)
                package = File.join(package, opts[:default_filename] || "datapackage.json")
            end
            if package.start_with?("http") && !package.end_with?("datapackage.json")
                package = URI.join(package, "datapackage.json")
            end
            @location = package.to_s
            JSON.parse( open(package).read )
          end
        end

        #Returns the directory for a local file package or base url for a remote
        #Returns nil for an in-memory object (because it has no base as yet)
        def base
            #user can override base
            return @opts[:base] if @opts[:base]
            return "" unless @location
            #work out base directory or uri
            if local?
                return File.dirname( @location )
            else
                return @location.split("/")[0..-2].join("/")
            end
        end

        #Is this a local package? Returns true if created from an in-memory object or a file/directory reference
        def local?
            return !@location.start_with?("http") if @location
            return true
        end

        def property(property, default=nil)
            @metadata[property] || default
        end

        def valid?(profile=:datapackage, strict=false)
            validator = DataPackage::Validator.create(profile, @opts)
            return validator.valid?(self, strict)
        end

        def validate(profile=:datapackage)
            validator = DataPackage::Validator.create(profile, @opts)
            return validator.validate(self)
        end

        def resolve_resource(resource)
            return resource["url"] || resolve( resource["path"] )
        end

        def resolve(path)
            if local?
                return File.join( base , path) if base != ""
                return path
            else
                return URI.join(base, path)
            end
        end

        def resource_exists?(location)
            if !location.to_s.start_with?("http")
                return File.exists?( location )
            else
                begin
                    status = RestClient.head( location ).code
                    return status == 200
                rescue => e
                    return false
                end
            end
        end

        def to_h
          @metadata
        end

        private

          def define_properties!
            (@schema["properties"] || {}).each do |k,v|
              define_singleton_method("#{k.to_sym}=", Proc.new { |p| set_property(k,p) } )
              define_singleton_method("#{k.to_sym}", Proc.new { property k, default_value(v) } )
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
            else
              nil
            end
          end

          def set_property(key, value)
            @metadata[key] = value
          end

    end
end
