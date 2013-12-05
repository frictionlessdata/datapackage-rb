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
            DateTime.parse @package["last_modified"] rescue nil 
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
            @package["dependencies"]
        end
        
        def property(property, default=nil)
            @package[property] || default
        end
        
        def valid?(profile=:datapackage, strict=false)
            messages = validate( profile ) 
            return messages[:errors].empty? if !strict
            return messages[:errors].empty? && messages[:warnings].empty? 
        end
        
        def validate(profile=:datapackage)
            return validate_package( validate_with_schema(profile), profile )
        end
        
        private
        
        def validate_with_schema(profile=:datapackage)
            schema = load_schema(profile)
            messages = {
                :errors => JSON::Validator.fully_validate(schema, @package, :errors_as_objects => true),
                :warnings => [] 
            }
            return messages
        end

        def validate_package(messages, profile=:datapackage)
            #not required, but recommended
            prefix = "The package does not include a"
            messages[:warnings] << "#{prefix} 'licenses' property" if licenses.empty?
            messages[:warnings] << "#{prefix} 'datapackage_version' property" unless datapackage_version 
            messages[:warnings] << "#{prefix} README.md file" unless resource_exists?( resolve("README.md") )
                
            resources.each do |resource|
                if !resource_exists?( resolve_resource( resource ) )
                    messages[:errors] << "Resource #{resource["url"] || resource["path"]} does not exist"
                end
            end
            
            messages
        end
                
        def load_schema(profile)
            if @opts[:schema] && @opts[:schema][profile]
                if !File.exists?( @opts[:schema][profile] )
                    raise "User supplied schema file does not exist: #{@opts[:schema][profile]}"
                end                 
                return JSON.parse( File.read( @opts[:schema][profile] ) )
            end
            schema_file = file_in_etc_directory( "#{profile}-schema.json" )
            if !File.exists?( schema_file )
                raise "Unable to read schema file #{schema_file} for validation profile #{profile}"
            end
            return JSON.parse( File.read( schema_file ) )
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
        
        def file_in_etc_directory(filename)
            File.join( File.dirname(__FILE__), "..", "..", "etc", filename )
        end
        
    end
end