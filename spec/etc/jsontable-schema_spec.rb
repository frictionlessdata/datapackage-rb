describe "JSON Table Schema" do

    before(:all) do
        @schema = load_schema("jsontable-schema.json")
    end

    it "will require fields" do
        data = {}
        expect( JSON::Validator.validate(@schema, data) ).to be(false)
        data["fields"] = []
        expect( JSON::Validator.validate(@schema, data) ).to be(false)
        data["fields"] = [ { "name"=>"" } ]
        expect( JSON::Validator.validate(@schema, data) ).to be(true)
    end

    it "requires fields to be named" do
        data = {
            "fields"=>[
                { "name" => "my-field" }
            ]
        }
        expect( JSON::Validator.validate(@schema, data) ).to be(true)
    end

    it "restricts valid types" do
        data = {
            "fields"=>[
                {
                    "name" => "my-field",
                    "type" => "unknown"
                }
            ]
        }
        expect( JSON::Validator.validate(@schema, data) ).to be(false)
        [ "string", "number", "integer", "date", "time", "datetime",
            "boolean", "binary", "object", "geopoint", "geojson", "array", "any" ].each do |type|
                data["fields"][0]["type"] = type
                expect( JSON::Validator.validate(@schema, data) ).to be(true)
        end
    end

end
