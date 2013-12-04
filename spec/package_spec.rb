require 'spec_helper'

describe DataPackage::Package do
    
    before(:each) do
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
            package = DataPackage::Package.new( test_package_filename )
            expect( package.name ).to eql("test-package")
            expect( package.resources.length ).to eql(1)            
        end
        
        it "should load from a directory" do
            package = DataPackage::Package.new( File.join( File.dirname(__FILE__), "test-pkg"), 
                {:default_filename=>"valid-datapackage.json"})
            expect( package.name ).to eql("test-package")
            expect( package.resources.length ).to eql(1)                
        end
        
        it "should load from am explicit URL" do
            FakeWeb.register_uri(:get, "http://example.com/datapackage.json", 
                :body => File.read( test_package_filename ) )
            package = DataPackage::Package.new( "http://example.com/datapackage.json" )    
            expect( package.name ).to eql("test-package")
            expect( package.resources.length ).to eql(1)                            
        end
        
        it "should load from a base URL" do            
            FakeWeb.register_uri(:get, "http://example.com/datapackage.json", 
                :body => File.read( test_package_filename ) )
            package = DataPackage::Package.new( "http://example.com/" )    
            expect( package.name ).to eql("test-package")
            expect( package.resources.length ).to eql(1)                            
        end
        
        it "should distinguish between local and remote packages" do
            package = DataPackage::Package.new( { "name" => "test"} )
            expect( package.local? ).to eql(true)
            expect( package.base ).to eql("")
            
            file = test_package_filename
            package = DataPackage::Package.new(file)
            expect( package.local? ).to eql(true)
            expect( package.base ).to eql( File.join( File.dirname(__FILE__),"test-pkg") )
            
            FakeWeb.register_uri(:get, "http://example.com/datapackage.json", 
                :body => File.read( test_package_filename ) )
            package = DataPackage::Package.new( "http://example.com/" )    
            expect( package.local? ).to eql(false)            
            expect( package.base ).to eql( "http://example.com" )
        end
        
    end
        
    #We're just testing simple validation options here, there are separate specs for testing the 
    #schema itself.
    context "when validating with the datapackage profile" do
        it "should validate basic datapackage structure" do
            package = DataPackage::Package.new(test_package_filename)
            expect( package.valid? ).to be(true)            
        end
        
        it "should detect invalid datapackages" do
            package = DataPackage::Package.new( { "name" => "this is invalid" } )
            expect( package.valid? ).to be(false)            
        end
        
        it "should allow user to specify a schema" do
            package = DataPackage::Package.new(test_package_filename, 
                { :schema => { 
                    :datapackage => File.join( 
                        File.dirname(__FILE__), "..", "etc", "datapackage-schema.json") 
                  }
                })
            expect( package.valid? ).to be(true)    
        end
        
        it "should raise an exception for missing user-supplied schemas" do
            package = DataPackage::Package.new(test_package_filename, 
                { :schema => { 
                    :datapackage => File.join( 
                        File.dirname(__FILE__), "..", "etc", "does-not-exist.json") 
                  }
                })            
            expect { package.valid?(:datapackage) }.to raise_error                
        end
        
        it "should raise an exception for unknown profiles" do
            package = DataPackage::Package.new(test_package_filename)
            expect { package.valid?(:unknown) }.to raise_error            
        end
        
        it "should distinguish between errors and warnings" do
            package = DataPackage::Package.new(test_package_filename)
            messages = package.validate( :datapackage )
            expect( messages[:errors] ).to eql([])
            expect( messages[:warnings] ).to eql([])
            
            package = DataPackage::Package.new( { 
                "name" => "testing", 
                "licenses"=>[{"id"=>"", "url"=>""}], 
                "datapackage_version"=>"" 
            } )
            messages = package.validate( :datapackage )
            #missing resources
            expect( messages[:errors].length ).to eql(1)
            #missing README
            expect( messages[:warnings] ).to_not be_empty                         
        end
                
        it "should provide warnings about missing useful keys" do
            package = DataPackage::Package.new( { 
                "name" => "testing" 
            } )
            messages = package.validate( :datapackage )
            expect( messages[:warnings] ).to_not be_empty                                     
        end
        
        it "should treat warnings as errors in strict mode" do
            package = DataPackage::Package.new( { 
                "name" => "testing" 
            } )
            messages = package.valid?( :datapackage )            
        end
        
        it "should warn if README.md is missing" do
            package = DataPackage::Package.new(test_package_filename)
            messages = package.validate( :datapackage )
            expect( messages[:warnings] ).to be_empty

            FakeWeb.register_uri(:get, "http://example.com/datapackage.json", 
                :body => File.read( test_package_filename ) )
            FakeWeb.register_uri(:head, "http://example.com/README.md", 
                :body => "", :status=>["404", "Not Found"] )
                                                                       
            package = DataPackage::Package.new( "http://example.com/" )
            messages = package.validate( :datapackage )
            expect( messages[:warnings] ).to_not be_empty                                          
        end
        
        it "should check that all files are accessible" do
            package = DataPackage::Package.new(test_package_filename)
            messages = package.validate( :datapackage )
            expect( messages[:errors] ).to be_empty
                
            data = JSON.parse( File.read( test_package_filename ) )
            #refer to missing resource
            data["resources"][0]["path"] = "oh-dear-its-gone.csv"
            #point test package at new base dir
            package = DataPackage::Package.new(data, { :base => File.join( File.dirname(__FILE__), "test-pkg") })
            messages = package.validate( :datapackage )
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
            messages = package.validate( :datapackage )
            expect( messages[:errors] ).to be_empty                                                        
        end
            
    end
    
#    context "when validating with the simpledataformat profile" do
#        it "should ensure that resources have a schema"
#        it "should validate the schema of a resource"
#        it "should validate the CSVDDF dialect of a resource"
#        
#        it "should ensure that every resource is a CSV file"
#        
#        it "should ensure that every CSV file has a header"
#        it "should detect fields missing from CSV file"
#        it "should detect fields missing from schema"
#        
#        #it "should check encoding of CSV files is UTF-8"
#    end 
end