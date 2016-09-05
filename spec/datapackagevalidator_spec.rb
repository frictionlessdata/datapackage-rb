describe DataPackage::DataPackageValidator do
    
    before(:each) do
        @validator = DataPackage::DataPackageValidator.new()
    end
    
    it "should distinguish between errors and warnings" do
        package = DataPackage::Package.new(test_package_filename)
        messages = @validator.validate( package )
        expect( messages[:errors] ).to eql([])
        expect( messages[:warnings] ).to eql([])
        
        package = DataPackage::Package.new( { 
            "name" => "testing", 
            "licenses"=>[{"id"=>"", "url"=>""}], 
            "datapackage_version"=>"" 
        }, { :base => Dir.tmpdir } )
        messages = @validator.validate( package )
        #missing resources
        expect( messages[:errors].length ).to eql(1)
        msg = messages[:errors][0]
        expect( msg[:type] ).to eql(:metadata)
            
        #missing README
        #Note: slightly fragile as this will fail if there's a README.md in /tmp
        expect( messages[:warnings] ).to_not be_empty
        msg = messages[:warnings][0]
        expect( msg[:type] ).to eql(:integrity)
                                    
    end  
    
    it "should provide warnings about missing useful keys" do
        package = DataPackage::Package.new( { 
            "name" => "testing",
            "resources" => [ { "path" => "data.csv" }]
        } )
        messages = @validator.validate( package )
        expect( messages[:warnings] ).to_not be_empty                                     
    end
    
    it "should treat warnings as errors in strict mode" do
        package = DataPackage::Package.new( { 
            "name" => "testing" 
        } )
        messages = @validator.valid?( package )            
    end
    
    it "should warn if README.md is missing" do
        package = DataPackage::Package.new(test_package_filename)
        messages = @validator.validate( package )
        expect( messages[:warnings] ).to be_empty

        FakeWeb.register_uri(:get, "http://example.com/datapackage.json", 
            :body => File.read( test_package_filename ) )
        FakeWeb.register_uri(:head, "http://example.com/README.md", 
            :body => "", :status=>["404", "Not Found"] )
                                                                   
        package = DataPackage::Package.new( "http://example.com/" )
        messages = @validator.validate( package )
        expect( messages[:warnings] ).to_not be_empty                              
    end
    
    it "should check that all files are accessible" do
        package = DataPackage::Package.new(test_package_filename)
        messages = @validator.validate( package )
        expect( messages[:errors] ).to be_empty
            
        data = JSON.parse( File.read( test_package_filename ) )
        #refer to missing resource
        data["resources"][0]["path"] = "oh-dear-its-gone.csv"
        #point test package at new base dir
        package = DataPackage::Package.new(data, { :base => File.join( File.dirname(__FILE__), "test-pkg") })
        messages = @validator.validate( package )
        expect( messages[:errors] ).to_not be_empty                                            
    end
    
    it "should check resource urls not just resource paths" do
        FakeWeb.register_uri(:head, "http://example.com/resource.csv", 
            :body => "data,here" )
        
        data = JSON.parse( File.read( test_package_filename ) )
        #refer to missing resource
        data["resources"][0].delete("path")
        data["resources"][0]["url"] = "http://example.com/resource.csv"
        #point test package at new base dir
        package = DataPackage::Package.new(data, { :base => File.join( File.dirname(__FILE__), "test-pkg") })
        messages = @validator.validate( package )
        expect( messages[:errors] ).to be_empty                                                        
    end    
        
end