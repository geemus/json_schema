require "test_helper"

require "json_schema"

describe JsonSchema::Parser do
  before do
    @parser = JsonSchema::Parser.new
  end

  it "parses the basic attributes of a schema" do
    schema = @parser.parse(data)
    assert_nil schema.id
    assert_equal "Example API", schema.title
    assert_equal "An example API.", schema.description
    assert_equal ["object"], schema.type
    assert_equal "/", schema.uri
  end

  it "parses subschemas" do
    schema = @parser.parse(data).definitions["app"]
    assert_nil schema.reference
    assert_equal "App", schema.title
    assert_equal "An app.", schema.description
    assert_equal "schemata/app", schema.id
    assert_equal ["object"], schema.type
    assert_equal "/schemata/app", schema.uri
    refute_nil schema.parent
  end

  it "parses sub-subschemas" do
    schema = @parser.parse(data).definitions["app"].definitions["name"]
    assert_nil schema.reference
    assert_equal "unique name of app", schema.description
    assert_equal ["string"], schema.type
    assert_equal "/schemata/app", schema.uri
    refute_nil schema.parent
  end

  it "parses references" do
    schema = @parser.parse(data).properties["app"]
    refute_nil schema.reference
    assert_nil schema.reference.uri
    assert_equal "#/definitions/app", schema.reference.pointer
    refute_nil schema.parent
  end

  it "parses array validations" do
    schema = @parser.parse(data).definitions["app"].definitions["flags"]
    assert_equal 0, schema.min_items
    assert_equal 10, schema.max_items
    assert_equal true, schema.unique_items
  end

  it "parses integer validations" do
    schema = @parser.parse(data).definitions["app"].definitions["dynos"]
    assert_equal 0, schema.min
    assert_equal false, schema.min_exclusive
    assert_equal 50, schema.max
    assert_equal false, schema.max_exclusive
    assert_equal 1, schema.multiple_of
  end

  it "parses number validations" do
    schema = @parser.parse(data).definitions["app"].definitions["cost"]
    assert_equal 0.0, schema.min
    assert_equal false, schema.min_exclusive
    assert_equal 1000.0, schema.max
    assert_equal true, schema.max_exclusive
    assert_equal 0.01, schema.multiple_of
  end

  it "errors on non-string ids" do
    local_data = data.dup
    local_data["id"] = 4
    e = assert_raises(RuntimeError) { @parser.parse(local_data) }
    assert_equal %{Expected "id" to be of type "String"; value was: 4.},
      e.message
  end

  it "errors on non-string titles" do
    local_data = data.dup
    local_data["title"] = 4
    e = assert_raises(RuntimeError) { @parser.parse(local_data) }
    assert_equal %{Expected "title" to be of type "String"; value was: 4.},
      e.message
  end

  it "errors on non-string descriptions" do
    local_data = data.dup
    local_data["description"] = 4
    e = assert_raises(RuntimeError) { @parser.parse(local_data) }
    assert_equal %{Expected "description" to be of type "String"; value was: 4.},
      e.message
  end

  it "errors on non-array and non-string types" do
    local_data = data.dup
    local_data["type"] = 4
    e = assert_raises(RuntimeError) { @parser.parse(local_data) }
    assert_equal %{Expected "type" to be of type "Array/String"; value was: 4.},
      e.message
  end

  it "errors on unknown types" do
    local_data = data.dup
    local_data["type"] = ["float", "double"]
    e = assert_raises(RuntimeError) { @parser.parse(local_data) }
    assert_equal %{Unknown types: double, float.},
      e.message
  end

  def data
    {
      "$schema" => "http://json-schema.org/draft-04/hyper-schema",
      "title" => "Example API",
      "description" => "An example API.",
      "type" => [
        "object"
      ],
      "definitions" => {
        "app" => {
          "$schema" => "http://json-schema.org/draft-04/hyper-schema",
          "title" => "App",
          "description" => "An app.",
          "id" => "schemata/app",
          "type" => [
            "object"
          ],
          "definitions" => {
            "cost" => {
              "description" => "running price of an app",
              "example" => 35.01,
              "max" => 1000.00,
              "maxExclusive" => true,
              "min" => 0.0,
              "minExclusive" => false,
              "multipleOf" => 0.01,
              "readOnly" => false,
              "type" => ["number"],
            },
            "dynos" => {
              "description" => "number of web dynos of an app",
              "example" => 1,
              "max" => 50,
              "maxExclusive" => false,
              "min" => 0,
              "minExclusive" => false,
              "multipleOf" => 1,
              "readOnly" => false,
              "type" => ["integer"],
            },
            "flags" => {
              "description" => "flags for an app",
              "example" => ["websockets"],
              "maxItems" => 10,
              "minItems" => 0,
              "readOnly" => false,
              "type" => ["array"],
              "uniqueItems" => true
            },
            "name" => {
              "description" => "unique name of app",
              "example" => "name",
              "readOnly" => false,
              "type" => ["string"]
            },
          },
          "properties" => {
            "app" => {
              "$ref" => "/schemata/app#/definitions/name"
            }
          }
        }
      },
      "properties" => {
        "app" => {
          "$ref" => "#/definitions/app"
        }
      },
      "links" => [
        {
          "href" => "http://example.com",
          "rel" => "self"
        }
      ]
    }
  end
end