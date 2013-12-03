require 'spec_helper'

describe "CSVDDF Dialect Schema" do
    
    before(:all) do
        @schema = load_schema("csvddf-dialect-schema.json")        
    end
    
    it "will validate a valid file" do
        valid = {
            "delimiter"=>",",
            "lineterminator"=>"\r\n",
            "quotechar"=>"\"",
            "doublequote"=>true,
            "skipinitialspace"=>true    
        }        
        expect( JSON::Validator.validate(@schema, valid) ).to be(true)
    end
    
    it "will reject invalid values" do
        invalid = {
            "delimiter"=>",",
            "lineterminator"=>"\r\n",
            "quotechar"=>"\"",
            "doublequote"=>"true",
            "skipinitialspace"=>true    
        }          
        expect( JSON::Validator.validate(@schema, invalid) ).to be(false)
    end  
    
    it "will reject incomplete structures" do
        data = {
        }          
        expect( JSON::Validator.validate(@schema, data) ).to be(false)
        data["delimiter"] = ","
        expect( JSON::Validator.validate(@schema, data) ).to be(false)
        data["lineterminator"] = "\r\n"
        expect( JSON::Validator.validate(@schema, data) ).to be(false)
        data["quotechar"] = "\""
        expect( JSON::Validator.validate(@schema, data) ).to be(false)
        data["doublequote"] = true
        expect( JSON::Validator.validate(@schema, data) ).to be(false)
        data["skipinitialspace"] = true
        expect( JSON::Validator.validate(@schema, data) ).to be(true)
    end    
      
end