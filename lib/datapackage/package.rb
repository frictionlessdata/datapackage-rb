require 'open-uri'

module DataPackage
    
    class Package
                
        attr_reader :package, :opts
                
        # Parse a data package
        #
        # Supports reading data from JSON file, directory, and a URL
        #
        # package:: Hash or a String
        # opts:: Options used to customize reading and parsing
        def initialize(package, opts={})
            @opts = opts
            #TODO base directory/url            
            if package.class == Hash
                @package = package
            else
                if !package.start_with?("http") && File.directory?(package)
                    package = File.join(package, opts[:default_filename] || "datapackage.json")
                end
                if package.start_with?("http") && !package.end_with?("datapackage.json")
                    package = URI.join(package, "datapackage.json")
                end                    
                @location = package.to_s
                @package = JSON.parse( open(package).read )                
            end
        end
        
        #Returns the directory for a local file package or base url for a remote
        #Returns nil for an in-memory object (because it has no base as yet)
        def base
            return nil unless @location
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
            @package["name"]
        end
        
        def title
            @package["title"]
        end
        
        def description
            @package["description"]
        end
        
        def homepage
            @package["homepage"]
        end
        
        def licenses
            @package["licenses"] || []
        end
        alias_method :licences, :licenses
        
        #What version of datapackage specification is this using?
        def datapackage_version
            @package["datapackage_version"]
        end
        
        #What is the version of this specific data package?
        def version
            @package["version"]
        end
        
        def sources
            @package["sources"] || []
        end
        
        def keywords
            @package["keywords"] || []
        end
        
        def last_modified
            Date.parse @package["last_modified"] 
        end
        
        def image
            @package["image"]
        end
        
        def maintainers
            @package["maintainers"] || []
        end
        
        def contributors
            @package["contributors"] || []
        end
        
        def publisher
            @package["publisher"] || []
        end
        
        def resources
            @package["resources"] || []
        end
        
        def dependencies
            @package["dependencies"] || []
        end
        
        def property(default=nil)
            @package[property] || default
        end
        
        def valid?(profile=:datapackage)
            schema = load_schema(profile)
            JSON::Validator.validate(schema, @package) 
        end
        
        def validate(profile=:datapackage)
            schema = load_schema(profile)
            JSON::Validator.fully_validate(schema, @package, :errors_as_objects => true) 
        end
        
        private
        
        def load_schema(profile)
            if @opts[:schema] && @opts[:schema][profile]
                return JSON.parse( File.read( @opts[:schema][profile] ) )
            end
            return JSON.parse( File.read( File.join( File.dirname(__FILE__), "..", "..", "etc", "#{profile}-schema.json" ) ) )
        end
        
    end
end