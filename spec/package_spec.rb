require 'spec_helper'

describe DataPackage::Package do
    
    before(:all) do
        FakeWeb.clean_registry
        FakeWeb.allow_net_connect = false        
    end
    
    context "when parsing packages" do
        it "should initialize from an object" do
            package = {
                "name" => "test-package",
                "description" => "description",
                "resources" => [ { "path" => "data.csv" }]
            }
            package = DataPackage::Package.new(package)
            expect( package.name ).to eql("test-package")
            expect( package.resources.length ).to eql(1)
        end
        
        it "should load from a local file" do
            file = File.join( File.dirname(__FILE__), "valid-datapackage.json")
            package = DataPackage::Package.new(file)
            expect( package.name ).to eql("csv-validation-example")
            expect( package.resources.length ).to eql(1)            
        end
        
        it "should load from a directory" do
            package = DataPackage::Package.new( File.dirname(__FILE__), {:default_filename=>"valid-datapackage.json"})
            expect( package.name ).to eql("csv-validation-example")
            expect( package.resources.length ).to eql(1)                
        end
        
        it "should load from am explicit URL" do
            FakeWeb.clean_registry
            FakeWeb.allow_net_connect = false
            
            FakeWeb.register_uri(:get, "http://example.com/datapackage.json", 
                :body => File.read( File.join( File.dirname(__FILE__), "valid-datapackage.json") ) )
            package = DataPackage::Package.new( "http://example.com/datapackage.json" )    
            expect( package.name ).to eql("csv-validation-example")
            expect( package.resources.length ).to eql(1)                            
        end
        
        it "should load from a base URL" do            
            FakeWeb.register_uri(:get, "http://example.com/datapackage.json", 
                :body => File.read( File.join( File.dirname(__FILE__), "valid-datapackage.json") ) )
            package = DataPackage::Package.new( "http://example.com/" )    
            expect( package.name ).to eql("csv-validation-example")
            expect( package.resources.length ).to eql(1)                            
        end
        
        it "should distinguish between local and remote packages" do
            package = DataPackage::Package.new( { "name" => "test"} )
            expect( package.local? ).to eql(true)
            expect( package.base ).to eql(nil)
            
            file = File.join( File.dirname(__FILE__), "valid-datapackage.json")
            package = DataPackage::Package.new(file)
            expect( package.local? ).to eql(true)
            expect( package.base ).to eql( File.dirname(__FILE__) )
            
            FakeWeb.register_uri(:get, "http://example.com/datapackage.json", 
                :body => File.read( File.join( File.dirname(__FILE__), "valid-datapackage.json") ) )
            package = DataPackage::Package.new( "http://example.com/" )    
            expect( package.local? ).to eql(false)            
            expect( package.base ).to eql( "http://example.com" )
        end
        
    end
        
    #We're just testing simple validation options here, there are separate specs for testing the 
    #schema itself.
    context "when validating with the datapackage profile" do
        it "should validate basic datapackage structure" do
            file = File.join( File.dirname(__FILE__), "valid-datapackage.json")
            package = DataPackage::Package.new(file)
            expect( package.valid? ).to be(true)            
        end
        
        it "should detect invalid datapackages" do
            package = DataPackage::Package.new( { "name" => "this is invalid" } )
            expect( package.valid? ).to be(false)            
        end
        
        it "should allow user to specify a schema" do
            file = File.join( File.dirname(__FILE__), "valid-datapackage.json")
            package = DataPackage::Package.new(file, 
                { :schema => { 
                    :datapackage => File.join( 
                        File.dirname(__FILE__), "..", "etc", "datapackage-schema.json") 
                  }
                })
            expect( package.valid? ).to be(true)    
        end
        
        it "should ignore unknown validation profiles"
        it "should raise an exception for missing schemas"
        
        it "should distinguish between errors and warnings"        
        it "should provide warnings about missing useful keys"
        it "should warn if README.md is missing"
        it "should check that all files are accessible"
    end
    
    context "when validating with the simpledataformat profile" do
        it "should ensure that resources have a schema"
        it "should validate the schema of a resource"
        it "should validate the CSVDDF dialect of a resource"
        
        it "should ensure that every resource is a CSV file"
        
        it "should ensure that every CSV file has a header"
        it "should detect fields missing from CSV file"
        it "should detect fields missing from schema"
        
        #it "should check encoding of CSV files is UTF-8"
    end 
end