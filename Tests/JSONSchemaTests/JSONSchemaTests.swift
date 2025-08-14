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
        "enum": .enum(
          description: "An enum of values",
          values: ["value1", 5, "value3", nil as JSONValue]
        ),
        "stringEnum": .enum(
          description: "A string enum",
          values: ["value1", "value2", "value3"]
        )
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
            "enum" : {
              "description" : "An enum of values",
              "enum" : [
                "value1",
                5,
                "value3",
                null
              ]
            },
            "number" : {
              "description" : "A test number",
              "maximum" : 100,
              "minimum" : 0,
              "type" : "number"
            },
            "stringEnum" : {
              "description" : "A string enum",
              "enum" : [
                "value1",
                "value2",
                "value3"
              ],
              "type" : "string"
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
          "enum" : {
            "description" : "An enum of values",
            "enum" : [
              "value1",
              5,
              "value3",
              null
            ]
          },
          "stringEnum" : {
            "description" : "A string enum",
            "enum" : [
              "value1",
              "value2",
              "value3"
            ],
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
    #expect(schema.object?.properties["stringEnum"]?.type == "string")
    #expect(schema.object?.properties["stringEnum"]?.enum?.values.count == 3)
    #expect(schema.object?.properties["stringEnum"]?.enum?.values == ["value1".jsonValue, "value2".jsonValue, "value3".jsonValue])
    #expect(schema.object?.properties["enum"]?.type == nil)
    #expect(schema.object?.properties["enum"]?.enum?.values.count == 4)
    #expect(schema.object?.properties["enum"]?.enum?.values == ["value1".jsonValue, 5.jsonValue, "value3".jsonValue, nil as JSONValue])
  }
}
