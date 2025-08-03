import JSONSchema
import Testing

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

struct JSONSchemaTests {
  @Test
  func testEncoding() {
    let schema: JSONSchema = .object(
      description: "My test object",
      properties: [
        "test": .string(description: "A test string", minLength: 1, maxLength: 10),
        "number": .number(description: "A test number", minimum: 0, maximum: 100),
        "array": .array(
          description: "A test array", items: .string(), minItems: 1, maxItems: 5, uniqueItems: true
        ),
      ], required: ["test", "number"],
      additionalProperties: .false)

    let encoder = JSONEncoder()

    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try! encoder.encode(schema)
    let jsonString = String(decoding: data, as: UTF8.self)
    #expect(
      jsonString == """
        {
          "additionalProperties" : false,
          "description" : "My test object",
          "properties" : {
            "array" : {
              "description" : "A test array",
              "items" : {
                "type" : "string"
              },
              "maxItems" : 5,
              "minItems" : 1,
              "type" : "array",
              "uniqueItems" : true
            },
            "number" : {
              "description" : "A test number",
              "maximum" : 100,
              "minimum" : 0,
              "type" : "number"
            },
            "test" : {
              "description" : "A test string",
              "maxLength" : 10,
              "minLength" : 1,
              "type" : "string"
            }
          },
          "required" : [
            "test",
            "number"
          ],
          "type" : "object"
        }
        """)
  }

  @Test func testDecoding() async throws {
    let jsonString = """
      {
        "additionalProperties" : false,
        "description" : "My test object",
        "properties" : {
          "array" : {
            "description" : "A test array",
            "items" : {
              "type" : "string"
            },
            "maxItems" : 5,
            "minItems" : 1,
            "type" : "array",
            "uniqueItems" : true
          },
          "number" : {
            "description" : "A test number",
            "maximum" : 100,
            "minimum" : 0,
            "type" : "number"
          },
          "test" : {
            "description" : "A test string",
            "maxLength" : 10,
            "minLength" : 1,
            "type" : "string"
          },
          "oneOrTheOther": {
            "oneOf": [
              {
                "type": "string"
              },
              {
                "type": "number"
              }
            ]
          }
        },
        "required" : [
          "test",
          "number"
        ],
        "type" : "object"
      }
      """

    let decoder = JSONDecoder()
    let schema = try decoder.decode(JSONSchema.self, from: Data(jsonString.utf8))
    #expect(schema.type == "object")
    #expect(schema.description == "My test object")
    #expect(schema.object?.properties["test"]?.type == "string")
    #expect(schema.object?.properties["test"]?.description == "A test string")
    #expect(schema.object?.properties["test"]?.string?.pattern == nil)
    #expect(schema.object?.properties["test"]?.string?.maxLength == 10)
    #expect(schema.object?.properties["test"]?.string?.minLength == 1)
    #expect(schema.object?.properties["number"]?.type == "number")
    #expect(schema.object?.properties["number"]?.description == "A test number")
    #expect(schema.object?.properties["number"]?.number?.minimum == 0)
    #expect(schema.object?.properties["number"]?.number?.maximum == 100)
    #expect(schema.object?.properties["array"]?.type == "array")
    #expect(schema.object?.properties["array"]?.description == "A test array")
    #expect(schema.object?.properties["array"]?.array?.minItems == 1)
    #expect(schema.object?.properties["array"]?.array?.maxItems == 5)
    #expect(schema.object?.properties["array"]?.array?.uniqueItems == true)
    #expect(schema.object?.properties["array"]?.array?.items.type == "string")
    #expect(schema.object?.additionalProperties?.isFalse == true)
    #expect(schema.object?.required == ["test", "number"])
    #expect(schema.object?.properties["oneOrTheOther"]?.oneOf?.count == 2)
    #expect(schema.object?.properties["oneOrTheOther"]?.oneOf?[0].type == "string")
    #expect(schema.object?.properties["oneOrTheOther"]?.oneOf?[1].type == "number")
  }

  @Test
  func testNewKeywordsEncoding() {
    let schema: JSONSchema = .object(
      title: "User Profile",
      description: "Complete user profile schema",
      properties: [
        "name": .string(
          title: "Full Name",
          description: "User's full name",
          default: "Anonymous",
          examples: ["John Doe", "Jane Smith"],
          minLength: 1,
          maxLength: 100
        ),
        "email": .string(
          title: "Email Address",
          description: "User's email address",
          format: "email",
          examples: ["user@example.com", "test@domain.org"]
        ),
        "age": .integer(
          title: "Age",
          description: "User's age in years",
          default: 18,
          examples: [25, 30, 45],
          minimum: 0,
          maximum: 150,
          multipleOf: 1
        ),
        "score": .number(
          title: "Test Score",
          description: "User's test score",
          default: 0.0,
          examples: [85.5, 92.3],
          exclusiveMinimum: 0,
          exclusiveMaximum: 100,
          multipleOf: 0.1
        ),
        "isActive": .boolean(
          title: "Active Status",
          description: "Whether the user is active",
          default: true,
          examples: [true, false]
        ),
        "status": .enum(
          title: "User Status",
          description: "Current user status",
          values: ["active", "inactive", "pending"]
        )
      ],
      required: ["name", "email"]
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try! encoder.encode(schema)
    let jsonString = String(decoding: data, as: UTF8.self)
    
    // Verify the new keywords are properly encoded
    #expect(jsonString.contains("\"title\" : \"User Profile\""))
    #expect(jsonString.contains("\"default\" : \"Anonymous\""))
    #expect(jsonString.contains("\"examples\" : ["))
    #expect(jsonString.contains("\"format\" : \"email\""))
    #expect(jsonString.contains("\"exclusiveMinimum\" : 0"))
    #expect(jsonString.contains("\"exclusiveMaximum\" : 100"))
    #expect(jsonString.contains("\"multipleOf\" : 0.1"))
  }

  @Test
  func testNewKeywordsDecoding() throws {
    let jsonString = """
      {
        "title": "User Profile",
        "description": "Complete user profile schema",
        "type": "object",
        "properties": {
          "name": {
            "title": "Full Name",
            "type": "string",
            "default": "Anonymous",
            "examples": ["John Doe", "Jane Smith"],
            "minLength": 1,
            "maxLength": 100
          },
          "email": {
            "title": "Email Address",
            "type": "string",
            "format": "email",
            "examples": ["user@example.com"]
          },
          "age": {
            "title": "Age",
            "type": "integer",
            "default": 18,
            "examples": [25, 30],
            "minimum": 0,
            "maximum": 150,
            "multipleOf": 1
          },
          "score": {
            "title": "Test Score",
            "type": "number",
            "default": 0.0,
            "examples": [85.5, 92.3],
            "exclusiveMinimum": 0,
            "exclusiveMaximum": 100,
            "multipleOf": 0.1
          },
          "isActive": {
            "title": "Active Status",
            "type": "boolean",
            "default": true,
            "examples": [true, false]
          },
          "priority": {
            "type": "string",
            "const": "high"
          }
        },
        "required": ["name", "email"]
      }
      """

    let decoder = JSONDecoder()
    let schema = try decoder.decode(JSONSchema.self, from: Data(jsonString.utf8))
    
    // Test object-level keywords
    #expect(schema.object?.title == "User Profile")
    #expect(schema.object?.description == "Complete user profile schema")
    
    // Test string keywords
    let nameProperty = schema.object?.properties["name"]
    #expect(nameProperty?.string?.title == "Full Name")
    #expect(nameProperty?.string?.default == "Anonymous")
    #expect(nameProperty?.string?.examples == ["John Doe", "Jane Smith"])
    
    let emailProperty = schema.object?.properties["email"]
    #expect(emailProperty?.string?.format == "email")
    #expect(emailProperty?.string?.examples == ["user@example.com"])
    
    // Test integer keywords
    let ageProperty = schema.object?.properties["age"]
    #expect(ageProperty?.integer?.title == "Age")
    #expect(ageProperty?.integer?.default == 18)
    #expect(ageProperty?.integer?.examples == [25, 30])
    #expect(ageProperty?.integer?.multipleOf == 1)
    
    // Test number keywords
    let scoreProperty = schema.object?.properties["score"]
    #expect(scoreProperty?.number?.title == "Test Score")
    #expect(scoreProperty?.number?.default == 0.0)
    #expect(scoreProperty?.number?.examples == [85.5, 92.3])
    #expect(scoreProperty?.number?.exclusiveMinimum == 0)
    #expect(scoreProperty?.number?.exclusiveMaximum == 100)
    #expect(scoreProperty?.number?.multipleOf == 0.1)
    
    // Test boolean keywords
    let isActiveProperty = schema.object?.properties["isActive"]
    #expect(isActiveProperty?.boolean?.title == "Active Status")
    #expect(isActiveProperty?.boolean?.default == true)
    #expect(isActiveProperty?.boolean?.examples == [true, false])
    
    // Test const keyword
    let priorityProperty = schema.object?.properties["priority"]
    #expect(priorityProperty?.string?.const == "high")
  }

  @Test
  func testConstKeyword() throws {
    // Test string const
    let stringConstSchema = JSONSchema.string(const: "exactly-this")
    let encoder = JSONEncoder()
    let data = try encoder.encode(stringConstSchema)
    let jsonString = String(decoding: data, as: UTF8.self)
    #expect(jsonString.contains("\"const\" : \"exactly-this\""))
    
    // Test integer const
    let intConstSchema = JSONSchema.integer(const: 42)
    let intData = try encoder.encode(intConstSchema)
    let intJsonString = String(decoding: intData, as: UTF8.self)
    #expect(intJsonString.contains("\"const\" : 42"))
    
    // Test boolean const
    let boolConstSchema = JSONSchema.boolean(const: true)
    let boolData = try encoder.encode(boolConstSchema)
    let boolJsonString = String(decoding: boolData, as: UTF8.self)
    #expect(boolJsonString.contains("\"const\" : true"))
  }

  @Test
  func testFormatKeyword() throws {
    let formatSchemas = [
      JSONSchema.string(format: "email"),
      JSONSchema.string(format: "date"),
      JSONSchema.string(format: "time"),
      JSONSchema.string(format: "date-time"),
      JSONSchema.string(format: "uri"),
      JSONSchema.string(format: "uuid"),
      JSONSchema.string(format: "ipv4"),
      JSONSchema.string(format: "ipv6")
    ]
    
    let encoder = JSONEncoder()
    for formatSchema in formatSchemas {
      let data = try encoder.encode(formatSchema)
      let jsonString = String(decoding: data, as: UTF8.self)
      #expect(jsonString.contains("\"format\""))
    }
  }

  @Test
  func testExclusiveBounds() throws {
    let schema = JSONSchema.number(
      exclusiveMinimum: 0.0,
      exclusiveMaximum: 100.0
    )
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(schema)
    let jsonString = String(decoding: data, as: UTF8.self)
    
    #expect(jsonString.contains("\"exclusiveMinimum\" : 0"))
    #expect(jsonString.contains("\"exclusiveMaximum\" : 100"))
    #expect(!jsonString.contains("\"minimum\""))
    #expect(!jsonString.contains("\"maximum\""))
  }

  @Test
  func testMultipleOfKeyword() throws {
    let intSchema = JSONSchema.integer(multipleOf: 5)
    let numberSchema = JSONSchema.number(multipleOf: 2.5)
    
    let encoder = JSONEncoder()
    
    let intData = try encoder.encode(intSchema)
    let intJsonString = String(decoding: intData, as: UTF8.self)
    #expect(intJsonString.contains("\"multipleOf\" : 5"))
    
    let numberData = try encoder.encode(numberSchema)
    let numberJsonString = String(decoding: numberData, as: UTF8.self)
    #expect(numberJsonString.contains("\"multipleOf\" : 2.5"))
  }
}
