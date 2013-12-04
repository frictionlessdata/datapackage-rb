require 'spec_helper'

describe DataPackage::Package do
    
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
            FakeWeb.clean_registry
            FakeWeb.allow_net_connect = false
            
            FakeWeb.register_uri(:get, "http://example.com/datapackage.json", 
                :body => File.read( File.join( File.dirname(__FILE__), "valid-datapackage.json") ) )
            package = DataPackage::Package.new( "http://example.com/" )    
            expect( package.name ).to eql("csv-validation-example")
            expect( package.resources.length ).to eql(1)                            
        end
        
    end
        
    #We're just testing simple validation options here, there are separate specs for testing the 
    #schema itself.
    context "when validating packages" do
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
        
    end
    
end    