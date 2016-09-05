describe "DataPackage Schema" do

    before(:all) do
        @schema = load_schema("datapackage-schema.json")
    end

    it "will require fields" do
        data = {}
        expect( JSON::Validator.validate(@schema, data) ).to be(false)
        data["name"] = "abc"
        expect( JSON::Validator.validate(@schema, data) ).to be(false)
        data["resources"] = []
        expect( JSON::Validator.validate(@schema, data) ).to be(false)
        data["resources"] = [ { "url"=>"" } ]
        expect( JSON::Validator.validate(@schema, data) ).to be(true)
    end

    it "validates licences" do
        data = {
            "name" => "abc",
            "resources" => [ { "url" => "" } ],
            "licences" => [ {} ]
        }
        expect( JSON::Validator.validate(@schema, data) ).to be(false)
        data["licences"][0]["id"] = "123"
        expect( JSON::Validator.validate(@schema, data) ).to be(true)
        data["licences"][0] = {}
        expect( JSON::Validator.validate(@schema, data) ).to be(false)
        data["licences"][0]["url"] = "http://example.org"
        expect( JSON::Validator.validate(@schema, data) ).to be(true)
        data["licences"][0]["id"] = "123"
        expect( JSON::Validator.validate(@schema, data) ).to be(true)
    end

    it "validates sources" do
        data = {
            "name" => "abc",
            "resources" => [ { "url" => "" } ],
            "sources" => [{}]
        }
        expect( JSON::Validator.validate(@schema, data) ).to be(false)
        data["sources"][0] = { "name" => "name" }
        expect( JSON::Validator.validate(@schema, data) ).to be(true)
        data["sources"][0] = { "email" => "name@example.org" }
        expect( JSON::Validator.validate(@schema, data) ).to be(true)
        data["sources"][0] = { "web" => "http://example.org" }
        expect( JSON::Validator.validate(@schema, data) ).to be(true)
    end

    it "validates maintainers, contributors, publisher" do
        ["maintainers", "contributors", "publisher"].each do |key|
            data = {
                "name" => "abc",
                "resources" => [ { "url" => "" } ],
                key => [ {} ]
            }
            expect( JSON::Validator.validate(@schema, data) ).to be(false)
            data[key][0] = { "name" => "name" }
            expect( JSON::Validator.validate(@schema, data) ).to be(true)
            data[key][0]["email"] = "name@example.org"
            expect( JSON::Validator.validate(@schema, data) ).to be(true)
            data[key][0]["web"] = "http://example.org"
            expect( JSON::Validator.validate(@schema, data) ).to be(true)
        end
    end

    it "will ensure that resources have a pointer" do
        data = {
            "name" => "abc",
            "resources" => [ {} ]
        }
        expect( JSON::Validator.validate(@schema, data) ).to be(false)
        data["resources"][0] = { "path" => "path" }
        expect( JSON::Validator.validate(@schema, data) ).to be(true)
        data["resources"][0] = { "url" => "url" }
        expect( JSON::Validator.validate(@schema, data) ).to be(true)
    end

end
