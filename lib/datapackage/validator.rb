module DataPackage
    
    #Base class for validators
    class Validator
                
        attr_reader :messages
        
        def Validator.create(profile, opts={})
            if profile == :simpledataformat
                return SimpleDataFormatValidator.new(profile, opts)
            end
            if profile == :datapackage
                return DataPackageValidator.new(profile, opts)
            end
            return Validator.new(profile, opts)
        end
                
        def initialize(schema_name, opts={})
            @schema_name = schema_name
            @opts = opts
        end
        
        def valid?(package, strict=false)
            validate( package )
            return @messages[:errors].empty? if !strict
            return @messages[:errors].empty? && @messages[:warnings].empty? 
        end
        
        def validate( package )
            @messages = {:errors=>[], :warnings=>[]}
            validate_with_schema( package )
            validate_integrity( package )
            return @messages
        end

        protected 

        def validate_with_schema(package)
            schema = load_schema(@schema_name)
            messages = JSON::Validator.fully_validate(schema, package.metadata, :errors_as_objects => true)
            @messages[:errors] += messages.each {|msg| msg[:type] = :metadata  } 
            validate_metadata(package)
        end

        def validate_integrity(package )            
            package.resources.each_with_index do |resource, idx|
                validate_resource( package, resource, "#/resources/#{idx}" )
            end            
        end
                
        #implement to perform additional validation on metadata
        def validate_metadata( package )
        end
        
        #implement for per-resource validation
        def validate_resource( package, resource, path )
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
        
        def add_error(type, message, fragment=nil)
            @messages[:errors] << create_message(type, message, fragment)
        end
        
        def add_warning(type, message, fragment=nil)
            @messages[:warnings] << create_message(type, message, fragment)
        end
        
        def create_message(type, message, fragment=nil)
            { :message => message, :type => type, :fragment => fragment }              
        end

        def rebase(base, fragment)
            return fragment.gsub("#/", base)
        end
                
        private
        
        def file_in_etc_directory(filename)
            File.join( File.dirname(__FILE__), "..", "..", "etc", filename )
        end
                
    end
    
    #Extends base class with some additional checks for DataPackage conformance.
    #
    #These include some warnings about missing metadata elements and an existence
    #check for all resources 
    class DataPackageValidator < Validator
        def initialize(schema_name=:datapackage, opts={})
            super(:datapackage, opts)
        end        
        
        def validate_metadata(package)
            #not required, but recommended
            prefix = "The package does not include a"
            add_warning( :metadata, "#{prefix} 'licenses' property", "#/") if package.licenses.empty?
            add_warning( :metadata, "#{prefix} 'datapackage_version' property", "#/") unless package.datapackage_version
            add_warning( :integrity, "#{prefix} README.md file" ) unless package.resource_exists?( package.resolve("README.md") ) 
        end
        
        def validate_resource( package, resource, path )
            if !package.resource_exists?( package.resolve_resource( resource ) )
                add_error( :integrity, "Missing resource #{resource["url"] || resource["path"]}", path)
            end            
        end
        
    end
    
    #Validator that checks whether a package conforms to the Simple Data Format profile
    class SimpleDataFormatValidator < DataPackageValidator
        
        def initialize(schema_name=:datapackage, opts={})
            super(:datapackage, opts)
            @jsontable_schema = load_schema(:jsontable)
            @csvddf_schema = load_schema("csvddf-dialect")
        end
        
        def validate_resource(package, resource, path)
            super(package, resource, path)
            
            if !csv?(resource)
                add_error(:integrity, "#{resource["name"]} is not a CSV file", path )
            else  
                schema = resource["schema"]              
                if !schema
                    add_error(:metadata, "#{resource["name"]} does not have a schema", path )
                else
                    messages = JSON::Validator.fully_validate(@jsontable_schema, schema, :errors_as_objects => true)
                    @messages[:errors] += adjust_messages(messages, :metadata, path + "/schema")                                                                                   
                end  
                          
                if resource["dialect"]
                    messages = JSON::Validator.fully_validate(@csvddf_schema, resource["dialect"], :errors_as_objects => true)
                    @messages[:errors] += @messages[:errors] += adjust_messages(messages, :metadata, path + "/dialect")
                end
                
                if package.resource_exists?( package.resolve_resource( resource ) )
                    if resource["schema"] && resource["schema"]["fields"]
                        fields = resource["schema"]["fields"]
                        declared_fields = fields.map{ |f| f["name"] }
                        headers = headers(package, resource)
                        
                        #set algebra to finding fields missing from schema and/or CSV file
                        missing_fields = declared_fields - headers
                        if missing_fields != []
                            add_error( :integrity, 
                                "Declared schema has fields not present in CSV file (#{missing_fields.join(",")})", 
                                path+"/schema/fields")
                        end
                        undeclared_fields = headers - declared_fields
                        if undeclared_fields != []
                            add_error( :integrity, 
                                "CSV file has fields missing from schema (#{undeclared_fields.join(",")})", 
                                path+"/schema/fields")
                        end                    
                    end
                end
            end
            
        end
                
        def csv?(resource)
            resource["mediatype"] == "text/csv" ||
            resource["format"] == "csv"       
        end  
        
        def headers(package, resource)
            headers = []
            opts = dialect_to_csv_options(resource["dialect"])
            CSV.open( package.resolve_resource(resource), "r", opts) do |csv|
                headers = csv.shift
            end
            return headers
        end
                            
        def dialect_to_csv_options(dialect)
            return {}
        end
        
        private
        
        #adjust message structure returned by JSON::Validator to add out type and
        #adjust fragment references when we're using sub-schemas
        def adjust_messages(messages, type, path)
            messages.each do |msg| 
                msg[:type]= type
                msg[:fragment] = rebase( path , msg[:fragment] )
            end 
            messages                               
        end
        
    end
        
end