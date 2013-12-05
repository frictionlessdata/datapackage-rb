require 'spec_helper'

describe DataPackage::SimpleDataFormatValidator do
    
    before(:each) do
        @validator = DataPackage::SimpleDataFormatValidator.new()
    end
        
    it "should ensure that resources have a schema" do
        package = DataPackage::Package.new(test_package_filename)
        expect( @validator.valid?( package ) ).to be(true)
        
        package.resources[0].delete("schema")            
        expect( @validator.valid?( package ) ).to be(false)        
    end
    
    it "should validate the schema of a resource" do
        package = DataPackage::Package.new(test_package_filename)
        package.resources[0]["schema"]["fields"][0].delete("name")            
        expect( @validator.valid?( package ) ).to be(false)                        
    end
    
    
    it "should validate the CSVDDF dialect of a resource" do
        package = DataPackage::Package.new(test_package_filename)
        package.resources[0]["dialect"].delete("delimiter")            
        expect( @validator.valid?( package ) ).to be(false)                                
    end
            
    it "should ensure that every resource is a CSV file" do
        package = DataPackage::Package.new(test_package_filename)
        package.resources[0].delete("format")
        package.resources[0].delete("mediatype")           
        expect( @validator.valid?( package ) ).to be(false)                                        
    end
            
    it "should ensure that every CSV file has a header"
    it "should detect fields missing from CSV file"
    it "should detect fields missing from schema"
            
    #it "should check encoding of CSV files is UTF-8" 

end