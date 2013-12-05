module DataPackage
    
    #Base class for validators
    class Validator
                
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
            messages = validate( package )
            return messages[:errors].empty? if !strict
            return messages[:errors].empty? && messages[:warnings].empty? 
        end
        
        def validate( package )
            return validate_integrity( package, validate_with_schema(package) )
        end

        def validate_with_schema(package)
            schema = load_schema(@schema_name)
            messages = {
                :errors => JSON::Validator.fully_validate(schema, package.metadata, :errors_as_objects => true),
                :warnings => [] 
            }
            validate_metadata(package, messages)
            return messages
        end

        def validate_integrity(package, messages={ :errors=>[], :warnings=>[] } )            
            package.resources.each do |resource|
                validate_resource(package, resource, messages)
            end
            
            messages
        end

        protected 
        
        #implement to perform additional validation on metadata
        def validate_metadata(package, messages)
        end
        
        #implement for per-resource validation
        def validate_resource(package, resource, messages)
        end
        
        protected
        
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
        
        def validate_metadata(package, messages)
            #not required, but recommended
            prefix = "The package does not include a"
            messages[:warnings] << "#{prefix} 'licenses' property" if package.licenses.empty?
            messages[:warnings] << "#{prefix} 'datapackage_version' property" unless package.datapackage_version 
            messages[:warnings] << "#{prefix} README.md file" unless package.resource_exists?( package.resolve("README.md") )            
        end
        
        def validate_resource(package, resource, messages)
            if !package.resource_exists?( package.resolve_resource( resource ) )
                messages[:errors] << "Resource #{resource["url"] || resource["path"]} does not exist"
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
        
        def validate_resource(package, resource, messages)
            super(package, resource, messages)
            
            if !csv?(resource)
                messages[:errors] << "#{resource["name"]} is not a CSV file"
            else                
                if !resource["schema"]
                    messages[:errors] << "#{resource["name"]} does not have a schema"
                else
                    messages[:errors] +=
                        JSON::Validator.fully_validate(@jsontable_schema, 
                            resource["schema"], :errors_as_objects => true)                                                           
                end            
                if resource["dialect"]
                    messages[:errors] +=
                        JSON::Validator.fully_validate(@csvddf_schema, 
                            resource["dialect"], :errors_as_objects => true)                                
                end
                
                if resource["schema"] && resource["schema"]["fields"]
                    fields = resource["schema"]["fields"]
                    declared_fields = fields.map{ |f| f["name"] }
                    headers = headers(package, resource)
                    
                    #set algebra to finding fields missing from schema and/or CSV file
                    missing_fields = declared_fields - headers
                    if missing_fields != []
                        messages[:errors] << 
                            "Declared schema has fields not present in CSV file (#{missing_fields.join(",")})"
                    end
                    undeclared_fields = headers - declared_fields
                    if undeclared_fields != []
                        messages[:errors] << "CSV file has fields missing from schema (#{undeclared_fields.join(",")})"
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
    end
        
end