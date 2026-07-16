import JSONSchema
import NewCodable
import Testing

#if canImport(FoundationEssentials)
    import FoundationEssentials
#else
    import Foundation
#endif

struct JSONSchemaTests {
    @Test
    func testEncoding() throws {
        let schema: JSONSchema = .object(
            description: "My test object",
            properties: [
                "test": .string(description: "A test string", minLength: 1, maxLength: 10),
                "number": .number(description: "A test number", minimum: 0, maximum: 100),
                "array": .array(
                    description: "A test array",
                    items: .string(),
                    minItems: 1,
                    maxItems: 5,
                    uniqueItems: true
                ),
                "enum": .enum(
                    description: "An enum of values",
                    values: ["value1", 5, "value3", nil as JSONValue]
                ),
                "stringEnum": .enum(
                    description: "A string enum",
                    values: ["value1", "value2", "value3"]
                ),
            ],
            required: ["test", "number"],
            additionalProperties: .false
        )

        let encoder = NewJSONEncoder()
        let data = try encoder.encode(schema)

        // Decode it back to verify round-trip
        let decoder = NewJSONDecoder()
        let decoded = try decoder.decode(JSONSchema.self, from: data)
        #expect(decoded.type == "object")
        #expect(decoded.description == "My test object")
        #expect(decoded.object?.properties["test"]?.type == "string")
        #expect(decoded.object?.properties["test"]?.string?.minLength == 1)
        #expect(decoded.object?.properties["test"]?.string?.maxLength == 10)
        #expect(decoded.object?.properties["number"]?.type == "number")
        #expect(decoded.object?.properties["number"]?.number?.minimum == 0)
        #expect(decoded.object?.properties["number"]?.number?.maximum == 100)
        #expect(decoded.object?.properties["array"]?.type == "array")
        #expect(decoded.object?.properties["array"]?.array?.minItems == 1)
        #expect(decoded.object?.properties["array"]?.array?.maxItems == 5)
        #expect(decoded.object?.properties["array"]?.array?.uniqueItems == true)
        #expect(decoded.object?.properties["array"]?.array?.items.type == "string")
        #expect(decoded.object?.additionalProperties?.isFalse == true)
        #expect(decoded.object?.required == ["test", "number"])
        #expect(decoded.object?.properties["stringEnum"]?.type == "string")
        #expect(decoded.object?.properties["stringEnum"]?.enum?.values.count == 3)
        #expect(decoded.object?.properties["enum"]?.type == nil)
        #expect(decoded.object?.properties["enum"]?.enum?.values.count == 4)
    }

    @Test
    func testDecoding() throws {
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

        let decoder = NewJSONDecoder()
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
        #expect(
            schema.object?.properties["stringEnum"]?.enum?.values == [
                "value1".jsonValue, "value2".jsonValue, "value3".jsonValue,
            ]
        )
        #expect(schema.object?.properties["enum"]?.type == nil)
        #expect(schema.object?.properties["enum"]?.enum?.values.count == 4)
        #expect(
            schema.object?.properties["enum"]?.enum?.values == [
                "value1".jsonValue, 5.jsonValue, "value3".jsonValue, nil as JSONValue,
            ]
        )
    }

    @Test
    func testBooleanSchemas() throws {
        let trueData = Data("true".utf8)
        let falseData = Data("false".utf8)

        let decoder = NewJSONDecoder()
        let trueSchema = try decoder.decode(JSONSchema.self, from: trueData)
        let falseSchema = try decoder.decode(JSONSchema.self, from: falseData)

        #expect(trueSchema.isTrue)
        #expect(falseSchema.isFalse)

        // Round-trip
        let encoder = NewJSONEncoder()
        let trueEncoded = try encoder.encode(trueSchema)
        let falseEncoded = try encoder.encode(falseSchema)
        #expect(String(decoding: trueEncoded, as: UTF8.self) == "true")
        #expect(String(decoding: falseEncoded, as: UTF8.self) == "false")
    }

    @Test
    func testEnumSchema() throws {
        let jsonString = """
            {
              "description": "Colors",
              "enum": ["red", "green", "blue"]
            }
            """

        let decoder = NewJSONDecoder()
        let schema = try decoder.decode(JSONSchema.self, from: Data(jsonString.utf8))
        #expect(schema.enum?.values.count == 3)
        #expect(schema.enum?.description == "Colors")

        // Round-trip
        let encoder = NewJSONEncoder()
        let encoded = try encoder.encode(schema)
        let roundTripped = try decoder.decode(JSONSchema.self, from: encoded)
        #expect(roundTripped == schema)
    }

    @Test
    func testMixedEnumSchema() throws {
        let jsonString = """
            {
              "enum": ["value1", 5, "value3", null]
            }
            """

        let decoder = NewJSONDecoder()
        let schema = try decoder.decode(JSONSchema.self, from: Data(jsonString.utf8))
        #expect(schema.enum?.values.count == 4)
        #expect(
            schema.enum?.values == [
                "value1".jsonValue, 5.jsonValue, "value3".jsonValue, nil as JSONValue,
            ]
        )
    }

    /// Equal object schemas must serialize to identical bytes: consumers use
    /// the encoded schema inside prompt-cache prefixes, where any byte flip
    /// (e.g. dictionary iteration order of `properties`) busts the cache.
    @Test
    func testObjectPropertiesEncodeInSortedKeyOrder() throws {
        let encoder = NewJSONEncoder()
        // Build the same schema with different insertion orders so the two
        // dictionaries get different storage layouts.
        let a: JSONSchema = .object(
            properties: [
                "text": .string(description: "The reminder text"),
                "due_date": .string(description: "When to remind"),
                "channel": .string(description: "Where to deliver"),
            ]
        )
        let b: JSONSchema = .object(
            properties: [
                "channel": .string(description: "Where to deliver"),
                "due_date": .string(description: "When to remind"),
                "text": .string(description: "The reminder text"),
            ]
        )
        let bytesA = try encoder.encode(a)
        let bytesB = try encoder.encode(b)
        #expect(bytesA == bytesB)
        let json = String(decoding: bytesA, as: UTF8.self)
        let order = ["channel", "due_date", "text"].compactMap { json.firstRange(of: "\"\($0)\"")?.lowerBound }
        #expect(order == order.sorted(), "properties keys must appear in sorted order: \(json)")
    }
}
