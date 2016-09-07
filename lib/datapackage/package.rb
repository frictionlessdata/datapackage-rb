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
          parse_package(package) unless package.nil?
        end

        def parse_package(package)
          #TODO base directory/url
          if package.class == Hash
              @metadata = package
          else
              if !package.start_with?("http") && File.directory?(package)
                  package = File.join(package, opts[:default_filename] || "datapackage.json")
              end
              if package.start_with?("http") && !package.end_with?("datapackage.json")
                  package = URI.join(package, "datapackage.json")
              end
              @location = package.to_s
              @metadata = JSON.parse( open(package).read )
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

        def name
            @metadata["name"]
        end

        def title
            @metadata["title"]
        end

        def description
            @metadata["description"]
        end

        def homepage
            @metadata["homepage"]
        end

        def licenses
            @metadata["licenses"] || []
        end
        alias_method :licences, :licenses

        #What version of datapackage specification is this using?
        def datapackage_version
            @metadata["datapackage_version"]
        end

        #What is the version of this specific data package?
        def version
            @metadata["version"]
        end

        def sources
            @metadata["sources"] || []
        end

        def keywords
            @metadata["keywords"] || []
        end

        def last_modified
            DateTime.parse @metadata["last_modified"] rescue nil
        end

        def image
            @metadata["image"]
        end

        def maintainers
            @metadata["maintainers"] || []
        end

        def contributors
            @metadata["contributors"] || []
        end

        def publisher
            @metadata["publisher"] || []
        end

        def resources
            @metadata["resources"] || []
        end

        def dependencies
            @metadata["dependencies"]
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

    end
end
