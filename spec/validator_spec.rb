describe DataPackage::Validator do
    
    before(:each) do
        @validator = DataPackage::Validator.new(:datapackage)
    end
    
    it "should instantiate correct sub-class" do
        validator = DataPackage::Validator.create(:datapackage)
        expect( validator.class ).to eql(DataPackage::DataPackageValidator)
        validator = DataPackage::Validator.create(:simpledataformat)
        expect( validator.class ).to eql(DataPackage::SimpleDataFormatValidator)
        validator = DataPackage::Validator.create(:other)
        expect( validator.class ).to eql(DataPackage::Validator)        
    end
    
    it "should validate basic datapackage structure" do
        package = DataPackage::Package.new(test_package_filename)
        expect( @validator.valid?( package ) ).to be(true)
        expect( @validator.valid?( package, true) ).to be(true)            
    end
    
    it "should detect invalid datapackages" do
        package = DataPackage::Package.new( { "name" => "this is invalid" } )
        expect( @validator.valid?( package ) ).to be(false)
        errors = @validator.messages[:errors]
        errors.each do |msg|
            expect( msg[:type] ).to eql(:metadata)
        end
    end
    
    it "should allow user to specify a schema" do
        package = DataPackage::Package.new(test_package_filename)
        @validator = DataPackage::Validator.new(:datapackage, { :schema => { 
                :datapackage => File.join( 
                    File.dirname(__FILE__), "..", "etc", "datapackage-schema.json") 
              }
            })
        expect( @validator.valid?( package ) ).to be(true)    
    end
    
    it "should raise an exception for missing user-supplied schemas" do
        package = DataPackage::Package.new(test_package_filename)
        @validator = DataPackage::Validator.new(:datapackage, { :schema => { 
                        :datapackage => File.join( 
                            File.dirname(__FILE__), "..", "etc", "does-not-exist.json") 
                      }})            
        expect { @validator.valid?( package ) }.to raise_error(
          RuntimeError,
          /User-supplied schema file does not exist/
        )
    end
    
    it "should raise an exception for unknown profiles" do
        package = DataPackage::Package.new(test_package_filename)
        @validator = DataPackage::Validator.new(:unknown)
        expect { @validator.valid?( package ) }.to raise_error(
          RuntimeError,
          /Unable to read schema file/
        )
    end
      
end