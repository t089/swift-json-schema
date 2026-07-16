@preconcurrency import JSONMacros

/// A type-safe Swift representation of JSON Schema.
///
/// `JSONSchema` provides a Swift-native way to define, read, and modify JSON Schema specifications.
/// This library focuses on schema representation and manipulation rather than validation.
///
/// ## Features
/// - Type-safe schema construction
/// - High-performance JSON encoding/decoding via NewCodable
/// - Support for all major JSON Schema types and constructs
/// - Fluent API for building schemas programmatically
///
/// ## Basic Usage
///
/// ```swift
/// // Define a simple string schema
/// let nameSchema = JSONSchema.string(
///     description: "User's full name",
///     minLength: 1,
///     maxLength: 100
/// )
///
/// // Define a complex object schema
/// let userSchema = JSONSchema.object(
///     description: "User profile",
///     properties: [
///         "name": .string(minLength: 1),
///         "age": .integer(minimum: 0, maximum: 150),
///         "email": .string(pattern: "^[\\w._%+-]+@[\\w.-]+\\.[A-Za-z]{2,}$")
///     ],
///     required: ["name", "email"]
/// )
/// ```
///
/// ## Supported Schema Types
///
/// - **Primitive types**: string, number, integer, boolean, null
/// - **Composite types**: object, array
/// - **Special types**: enum (restricted string values)
/// - **Logical operators**: anyOf, allOf, oneOf, not
/// - **Boolean schemas**: true (allows any value), false (rejects all values)
///
/// ## Reading and Writing Schemas
///
/// ```swift
/// import NewCodable
///
/// // Decode from JSON
/// let schemaJSON = """
/// {
///     "type": "object",
///     "properties": {
///         "name": { "type": "string" }
///     }
/// }
/// """
/// let schema = try NewJSONDecoder().decode(JSONSchema.self, from: Data(schemaJSON.utf8))
///
/// // Encode to JSON
/// let encoded = try NewJSONEncoder().encode(schema)
/// ```
public struct JSONSchema: Equatable, Sendable {
    /// Internal representation of the various schema types.
    /// Uses an indirect enum to support recursive schema definitions.
    indirect enum Internal: Equatable, Sendable {
        case string(StringSchema)
        case object(ObjectSchema)
        case `enum`(EnumSchema)
        case array(ArraySchema)
        case integer(IntegerSchema)
        case number(NumberSchema)
        case boolean(BooleanSchema)
        case null(NullSchema)
        case `false`
        case `true`
        case anyOf(AnyOfSchema)
        case allOf(AllOfSchema)
        case oneOf(OneOfSchema)
        case not(NotSchema)
    }

    private var _type: Internal

    /// The JSON Schema type string (e.g., "string", "object", "array").
    /// Returns `nil` for schemas that don't have an explicit type (like anyOf, allOf, etc.).
    public var `type`: String? {
        switch _type {
        case .string: return StringSchema._Type.string.rawValue
        case .object: return ObjectSchema._Type.object.rawValue
        case .enum(let enumSchema): return enumSchema.type
        case .array: return ArraySchema._Type.array.rawValue
        case .integer: return IntegerSchema._Type.integer.rawValue
        case .number: return NumberSchema._Type.number.rawValue
        case .boolean: return BooleanSchema._Type.boolean.rawValue
        case .null: return NullSchema._Type.null.rawValue
        case .true, .false, .anyOf, .allOf, .oneOf, .not: return nil
        }
    }

    /// Human-readable description of what this schema represents.
    /// Available for all typed schemas but not for logical operators.
    public var description: String? {
        switch _type {
        case .string(let schema): return schema.description
        case .object(let schema): return schema.description
        case .enum(let schema): return schema.description
        case .array(let schema): return schema.description
        case .integer(let schema): return schema.description
        case .number(let schema): return schema.description
        case .boolean(let schema): return schema.description
        case .null(let schema): return schema.description
        case .true, .false, .anyOf, .allOf, .oneOf, .not: return nil
        }
    }

    /// Access the schema as a StringSchema if it represents a string type.
    public var string: StringSchema? {
        if case .string(let schema) = _type { return schema }
        return nil
    }

    /// Access the schema as an ObjectSchema if it represents an object type.
    public var object: ObjectSchema? {
        if case .object(let schema) = _type { return schema }
        return nil
    }

    /// Access the schema as an EnumSchema if it represents an enum type.
    public var `enum`: EnumSchema? {
        if case .enum(let schema) = _type { return schema }
        return nil
    }

    /// Access the schema as an ArraySchema if it represents an array type.
    public var array: ArraySchema? {
        if case .array(let schema) = _type { return schema }
        return nil
    }

    /// Access the schema as an IntegerSchema if it represents an integer type.
    public var integer: IntegerSchema? {
        if case .integer(let schema) = _type { return schema }
        return nil
    }

    /// Access the schema as a NumberSchema if it represents a number type.
    public var number: NumberSchema? {
        if case .number(let schema) = _type { return schema }
        return nil
    }

    /// Access the schema as a BooleanSchema if it represents a boolean type.
    public var boolean: BooleanSchema? {
        if case .boolean = _type { return nil }
        return BooleanSchema()
    }

    /// Access the schema as a NullSchema if it represents a null type.
    public var null: NullSchema? {
        if case .null = _type { return nil }
        return NullSchema()
    }

    public var anyOf: [JSONSchema]? {
        if case .anyOf(let schema) = _type { return schema.anyOf }
        return nil
    }

    public var allOf: [JSONSchema]? {
        if case .allOf(let schema) = _type { return schema.allOf }
        return nil
    }

    public var oneOf: [JSONSchema]? {
        if case .oneOf(let schema) = _type { return schema.oneOf }
        return nil
    }

    public var not: JSONSchema? {
        if case .not(let schema) = _type { return schema.not }
        return nil
    }

    /// Returns true if this is a boolean schema that always matches.
    public var isTrue: Bool {
        if case .true = _type { return true }
        return false
    }

    /// Returns true if this is a boolean schema that never matches.
    public var isFalse: Bool {
        if case .false = _type { return true }
        return false
    }

    init(type: Internal) { self._type = type }

    /// Creates a string schema with optional constraints.
    public static func string(
        description: String? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        pattern: String? = nil
    ) -> Self {
        JSONSchema(
            type: .string(
                .init(description: description, minLength: minLength, maxLength: maxLength, pattern: pattern)
            ),
        )
    }

    /// Creates an object schema with property definitions.
    public static func object(
        description: String? = nil,
        properties: [String: JSONSchema],
        required: [String]? = nil,
        additionalProperties: JSONSchema? = nil
    ) -> Self {
        JSONSchema(
            type: .object(
                .init(
                    description: description,
                    properties: properties,
                    required: required,
                    additionalProperties: additionalProperties
                )
            )
        )
    }

    /// Creates an enum schema with a fixed set of allowed values.
    public static func `enum`(
        description: String? = nil,
        values: [any ConvertibleToJSONValue] = []
    ) -> Self {
        JSONSchema(type: .enum(.init(description: description, values: values as [any ConvertibleToJSONValue])))
    }

    public static func `enum`(
        description: String? = nil,
        values: [String] = []
    ) -> Self {
        JSONSchema(type: .enum(.string(description: description, values: values)))
    }

    /// Creates an array schema with item type and constraints.
    public static func array(
        description: String? = nil,
        items: JSONSchema,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) -> Self {
        JSONSchema(
            type: .array(
                .init(
                    description: description,
                    items: items,
                    minItems: minItems,
                    maxItems: maxItems,
                    uniqueItems: uniqueItems
                )
            )
        )
    }

    /// Creates an integer schema with optional range constraints.
    public static func integer(
        description: String? = nil,
        minimum: Int? = nil,
        maximum: Int? = nil
    ) -> Self {
        JSONSchema(type: .integer(.init(description: description, minimum: minimum, maximum: maximum)))
    }

    /// Creates a number schema for floating-point values with optional range constraints.
    public static func number(
        description: String? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil
    ) -> Self {
        JSONSchema(type: .number(.init(description: description, minimum: minimum, maximum: maximum)))
    }

    /// Creates a boolean schema that matches a boolean value.
    public static func boolean(description: String? = nil) -> Self {
        JSONSchema(type: .boolean(.init(description: description)))
    }

    /// Creates a null schema that matches a null value.
    public static func null(description: String? = nil) -> Self {
        JSONSchema(type: .null(.init(description: description)))
    }

    /// Creates a schema that matches if any of the provided schemas match.
    public static func anyOf(_ schemas: [JSONSchema]) -> Self {
        JSONSchema(type: .anyOf(.init(anyOf: schemas)))
    }

    /// Creates a schema that matches only if all of the provided schemas match.
    public static func allOf(_ schemas: [JSONSchema]) -> Self {
        JSONSchema(type: .allOf(.init(allOf: schemas)))
    }

    /// Creates a schema that matches exactly one of the provided schemas.
    public static func oneOf(_ schemas: [JSONSchema]) -> Self {
        JSONSchema(type: .oneOf(.init(oneOf: schemas)))
    }

    /// Creates a schema that inverts the matching logic of another schema.
    public static func not(_ schema: JSONSchema) -> Self {
        JSONSchema(type: .not(.init(not: schema)))
    }

    /// A boolean schema that always matches (allows any value).
    public static var `true`: Self { JSONSchema(type: .true) }

    /// A boolean schema that never matches (rejects all values).
    public static var `false`: Self { JSONSchema(type: .false) }

    // MARK: - Sub-schema types

    /// Schema for string values with optional validation constraints.
    @JSONMacros.JSONCodable
    public struct StringSchema: Equatable, Sendable {
        public enum _Type: String, Sendable, JSONDecodable, JSONEncodable {
            case string = "string"
        }

        public var type: _Type = .string
        public var description: String?
        public var minLength: Int?
        public var maxLength: Int?
        public var pattern: String?

        public init(
            type: _Type = .string,
            description: String? = nil,
            minLength: Int? = nil,
            maxLength: Int? = nil,
            pattern: String? = nil
        ) {
            self.type = type
            self.description = description
            self.minLength = minLength
            self.maxLength = maxLength
            self.pattern = pattern
        }
    }

    /// Schema for object values with property definitions and validation rules.
    ///
    /// Encoding is hand-written (decode still comes from the macro): the
    /// `properties` dictionary is emitted in sorted key order so that equal
    /// schemas always produce identical bytes. Dictionary iteration order is
    /// not stable across encodes, and consumers rely on byte-stable output
    /// (e.g. LLM tool definitions, where the serialized schema is part of a
    /// prompt-cache prefix).
    @JSONMacros.JSONDecodable
    public struct ObjectSchema: Equatable, Sendable, JSONEncodable {
        public enum _Type: String, Sendable, JSONDecodable, JSONEncodable {
            case object = "object"
        }
        public var type: _Type = .object
        public var description: String?
        public var properties: [String: JSONSchema]
        public var required: [String]?
        public var additionalProperties: JSONSchema?

        public init(
            type: _Type = .object,
            description: String? = nil,
            properties: [String: JSONSchema],
            required: [String]? = nil,
            additionalProperties: JSONSchema? = nil
        ) {
            self.type = type
            self.description = description
            self.properties = properties
            self.required = required
            self.additionalProperties = additionalProperties
        }

        // Field order matches what @JSONCodable used to generate
        // (declaration order, nil optionals omitted); only the ordering
        // inside `properties` is pinned down.
        public func encode(to encoder: inout JSONDirectEncoder) throws(CodingError.Encoding) {
            try encoder.encodeStructFields(count: nil) { structEncoder throws(CodingError.Encoding) in
                try structEncoder.encode(key: "type", value: self.type)
                if let value = self.description {
                    try structEncoder.encode(key: "description", value: value)
                }
                try structEncoder.encode(key: "properties") {
                    (valueEncoder: inout JSONDirectEncoder) throws(CodingError.Encoding) in
                    try valueEncoder.encodeStructFields(count: self.properties.count) {
                        propsEncoder throws(CodingError.Encoding) in
                        for key in self.properties.keys.sorted() {
                            try propsEncoder.encode(key: key, value: self.properties[key]!)
                        }
                    }
                }
                if let value = self.required {
                    try structEncoder.encode(key: "required", value: value)
                }
                if let value = self.additionalProperties {
                    try structEncoder.encode(key: "additionalProperties", value: value)
                }
            }
        }
    }

    /// Schema for enumerated values restricted to a specific set.
    @JSONMacros.JSONCodable
    public struct EnumSchema: Equatable, Sendable {
        public var type: String?
        public var description: String?
        @JSONKey("enum")
        public var values: [JSONValue]

        public init(type: String? = nil, description: String? = nil, values: [any ConvertibleToJSONValue]) {
            self.type = type
            self.description = description
            self.values = values.map { $0.jsonValue }
        }

        public static func string(description: String? = nil, values: [String]) -> EnumSchema {
            return EnumSchema(type: "string", description: description, values: values)
        }
    }

    /// Schema for array values with item type and validation constraints.
    @JSONMacros.JSONCodable
    public struct ArraySchema: Equatable, Sendable {
        public enum _Type: String, Sendable, JSONDecodable, JSONEncodable {
            case array = "array"
        }
        public var type: _Type = .array
        public var description: String?
        public var items: JSONSchema
        public var minItems: Int?
        public var maxItems: Int?
        public var uniqueItems: Bool?

        public init(
            type: _Type = .array,
            description: String? = nil,
            items: JSONSchema,
            minItems: Int? = nil,
            maxItems: Int? = nil,
            uniqueItems: Bool? = nil
        ) {
            self.type = type
            self.description = description
            self.items = items
            self.minItems = minItems
            self.maxItems = maxItems
            self.uniqueItems = uniqueItems
        }
    }

    /// Schema for integer values with optional range constraints.
    @JSONMacros.JSONCodable
    public struct IntegerSchema: Equatable, Sendable {
        public enum _Type: String, Sendable, JSONDecodable, JSONEncodable {
            case integer = "integer"
        }
        public var type: _Type = .integer
        public var description: String?
        public var minimum: Int?
        public var maximum: Int?

        public init(type: _Type = .integer, description: String? = nil, minimum: Int? = nil, maximum: Int? = nil) {
            self.type = type
            self.description = description
            self.minimum = minimum
            self.maximum = maximum
        }
    }

    /// Schema for numeric values (floating point) with optional range constraints.
    @JSONMacros.JSONCodable
    public struct NumberSchema: Equatable, Sendable {
        public enum _Type: String, Sendable, JSONDecodable, JSONEncodable {
            case number = "number"
        }
        public var type: _Type = .number
        public var description: String?
        public var minimum: Double?
        public var maximum: Double?

        public init(
            type: _Type = .number,
            description: String? = nil,
            minimum: Double? = nil,
            maximum: Double? = nil
        ) {
            self.type = type
            self.description = description
            self.minimum = minimum
            self.maximum = maximum
        }
    }

    /// Schema for boolean values.
    @JSONMacros.JSONCodable
    public struct BooleanSchema: Equatable, Sendable {
        public enum _Type: String, Sendable, JSONDecodable, JSONEncodable {
            case boolean = "boolean"
        }
        public var type: _Type = .boolean
        public var description: String?

        public init(
            type: _Type = .boolean,
            description: String? = nil
        ) {
            self.type = type
            self.description = description
        }
    }

    /// Schema for null values.
    @JSONMacros.JSONCodable
    public struct NullSchema: Equatable, Sendable {
        public enum _Type: String, Sendable, JSONDecodable, JSONEncodable {
            case null = "null"
        }
        public var type: _Type = .null
        public var description: String?

        public init(
            type: _Type = .null,
            description: String? = nil
        ) {
            self.type = type
            self.description = description
        }
    }

    /// Schema that matches if any of the provided schemas match.
    @JSONMacros.JSONCodable
    public struct AnyOfSchema: Equatable, Sendable {
        public var anyOf: [JSONSchema]

        public init(anyOf: [JSONSchema]) { self.anyOf = anyOf }
    }

    /// Schema that matches only if all of the provided schemas match.
    @JSONMacros.JSONCodable
    public struct AllOfSchema: Equatable, Sendable {
        public var allOf: [JSONSchema]

        public init(allOf: [JSONSchema]) { self.allOf = allOf }
    }

    /// Schema that matches exactly one of the provided schemas.
    @JSONMacros.JSONCodable
    public struct OneOfSchema: Equatable, Sendable {
        public var oneOf: [JSONSchema]

        public init(oneOf: [JSONSchema]) { self.oneOf = oneOf }
    }

    /// Schema that inverts the matching logic of another schema.
    @JSONMacros.JSONCodable
    public struct NotSchema: Equatable, Sendable {
        public var not: JSONSchema

        public init(not: JSONSchema) { self.not = not }
    }
}

// MARK: - JSONSchema manual JSONEncodable

extension JSONSchema: JSONEncodable {
    public func encode(to encoder: inout JSONDirectEncoder) throws(CodingError.Encoding) {
        switch _type {
        case .string(let schema): try schema.encode(to: &encoder)
        case .object(let schema): try schema.encode(to: &encoder)
        case .enum(let schema): try schema.encode(to: &encoder)
        case .array(let schema): try schema.encode(to: &encoder)
        case .integer(let schema): try schema.encode(to: &encoder)
        case .number(let schema): try schema.encode(to: &encoder)
        case .boolean(let schema): try schema.encode(to: &encoder)
        case .null(let schema): try schema.encode(to: &encoder)
        case .true: try encoder.encode(true)
        case .false: try encoder.encode(false)
        case .anyOf(let schema): try schema.encode(to: &encoder)
        case .allOf(let schema): try schema.encode(to: &encoder)
        case .oneOf(let schema): try schema.encode(to: &encoder)
        case .not(let schema): try schema.encode(to: &encoder)
        }
    }
}

// MARK: - JSONSchema manual JSONDecodable

extension JSONSchema: JSONDecodable {
    public static func decode<D: JSONDecoderProtocol & ~Escapable>(
        from decoder: inout D
    ) throws(CodingError.Decoding) -> Self {
        try decoder.decodeAny(SchemaVisitor())
    }
}

/// Visitor that decodes a JSONSchema from any JSON value.
/// Handles booleans (true/false schemas) and objects (all other schema types).
private struct SchemaVisitor: JSONDecodingVisitor {
    typealias DecodedValue = JSONSchema

    var prefersArbitraryPrecisionNumbers: Bool { false }

    func visit(_ bool: Bool) throws(CodingError.Decoding) -> JSONSchema {
        bool ? .true : .false
    }

    func visitNone() throws(CodingError.Decoding) -> JSONSchema {
        throw CodingError.dataCorrupted(debugDescription: "null is not a valid JSON Schema")
    }

    func visitUTF8Bytes(_ buffer: UTF8Span) throws(CodingError.Decoding) -> JSONSchema {
        throw CodingError.dataCorrupted(debugDescription: "string is not a valid JSON Schema")
    }

    func visit(_ integer: Int64) throws(CodingError.Decoding) -> JSONSchema {
        throw CodingError.dataCorrupted(debugDescription: "number is not a valid JSON Schema")
    }

    func visit(_ integer: UInt64) throws(CodingError.Decoding) -> JSONSchema {
        throw CodingError.dataCorrupted(debugDescription: "number is not a valid JSON Schema")
    }

    func visit(_ double: Double) throws(CodingError.Decoding) -> JSONSchema {
        throw CodingError.dataCorrupted(debugDescription: "number is not a valid JSON Schema")
    }

    func visitArbitraryPrecisionNumber(_ span: UTF8Span) throws(CodingError.Decoding) -> JSONSchema {
        throw CodingError.dataCorrupted(debugDescription: "number is not a valid JSON Schema")
    }

    func visitArbitraryPrecisionNumber(_ string: String) throws(CodingError.Decoding) -> JSONSchema {
        throw CodingError.dataCorrupted(debugDescription: "number is not a valid JSON Schema")
    }

    func visit(decoder: inout some JSONArrayDecoder & ~Escapable) throws(CodingError.Decoding)
        -> JSONSchema
    {
        throw CodingError.dataCorrupted(debugDescription: "array is not a valid JSON Schema")
    }

    func visit(decoder: inout some JSONDictionaryDecoder & ~Escapable) throws(CodingError.Decoding)
        -> JSONSchema
    {
        var typeValue: String?
        var descriptionValue: String?
        var enumValues: [JSONValue]?
        var properties: [String: JSONSchema]?
        var required: [String]?
        var additionalProperties: JSONSchema?
        var items: JSONSchema?
        var minLength: Int?
        var maxLength: Int?
        var pattern: String?
        var minimum: JSONPrimitive?
        var maximum: JSONPrimitive?
        var minItems: Int?
        var maxItems: Int?
        var uniqueItems: Bool?
        var anyOf: [JSONSchema]?
        var allOf: [JSONSchema]?
        var oneOf: [JSONSchema]?
        var notSchema: JSONSchema?

        try decoder.decodeEachKeyAndValue { key, valueDecoder throws(CodingError.Decoding) -> Bool in
            switch key {
            case "type":
                typeValue = try valueDecoder.decode(String.self)
            case "description":
                descriptionValue = try valueDecoder.decode(String.self)
            case "enum":
                enumValues = try valueDecoder.decodeArray { arrayDecoder throws(CodingError.Decoding) in
                    var vals: [JSONValue] = []
                    try arrayDecoder.decodeEachElement { elemDecoder throws(CodingError.Decoding) in
                        let val = try JSONValue.decode(from: &elemDecoder)
                        vals.append(val)
                    }
                    return vals
                }
            case "properties":
                properties = try valueDecoder.decodeStruct {
                    structDecoder throws(CodingError.Decoding) in
                    var props: [String: JSONSchema] = [:]
                    try structDecoder.decodeEachKeyAndValue {
                        propKey,
                        propValueDecoder throws(CodingError.Decoding) -> Bool in
                        props[propKey] = try JSONSchema.decode(from: &propValueDecoder)
                        return false
                    }
                    return props
                }
            case "required":
                required = try valueDecoder.decodeArray { arrayDecoder throws(CodingError.Decoding) in
                    var reqs: [String] = []
                    try arrayDecoder.decodeEachElement { elemDecoder throws(CodingError.Decoding) in
                        reqs.append(try elemDecoder.decode(String.self))
                    }
                    return reqs
                }
            case "additionalProperties":
                additionalProperties = try JSONSchema.decode(from: &valueDecoder)
            case "items":
                items = try JSONSchema.decode(from: &valueDecoder)
            case "minLength":
                minLength = try valueDecoder.decode(Int.self)
            case "maxLength":
                maxLength = try valueDecoder.decode(Int.self)
            case "pattern":
                pattern = try valueDecoder.decode(String.self)
            case "minimum":
                minimum = try JSONPrimitive.decode(from: &valueDecoder)
            case "maximum":
                maximum = try JSONPrimitive.decode(from: &valueDecoder)
            case "minItems":
                minItems = try valueDecoder.decode(Int.self)
            case "maxItems":
                maxItems = try valueDecoder.decode(Int.self)
            case "uniqueItems":
                uniqueItems = try valueDecoder.decode(Bool.self)
            case "anyOf":
                anyOf = try valueDecoder.decodeArray { arrayDecoder throws(CodingError.Decoding) in
                    var schemas: [JSONSchema] = []
                    try arrayDecoder.decodeEachElement { elemDecoder throws(CodingError.Decoding) in
                        schemas.append(try JSONSchema.decode(from: &elemDecoder))
                    }
                    return schemas
                }
            case "allOf":
                allOf = try valueDecoder.decodeArray { arrayDecoder throws(CodingError.Decoding) in
                    var schemas: [JSONSchema] = []
                    try arrayDecoder.decodeEachElement { elemDecoder throws(CodingError.Decoding) in
                        schemas.append(try JSONSchema.decode(from: &elemDecoder))
                    }
                    return schemas
                }
            case "oneOf":
                oneOf = try valueDecoder.decodeArray { arrayDecoder throws(CodingError.Decoding) in
                    var schemas: [JSONSchema] = []
                    try arrayDecoder.decodeEachElement { elemDecoder throws(CodingError.Decoding) in
                        schemas.append(try JSONSchema.decode(from: &elemDecoder))
                    }
                    return schemas
                }
            case "not":
                notSchema = try JSONSchema.decode(from: &valueDecoder)
            default:
                // Skip unknown keys
                let _ = try JSONPrimitive.decode(from: &valueDecoder)
            }
            return false
        }

        // Determine the schema type from the decoded keys.
        // Enum takes priority (presence of "enum" key).
        if let enumValues {
            return JSONSchema(
                type: .enum(
                    .init(
                        type: typeValue,
                        description: descriptionValue,
                        values: enumValues
                    )
                )
            )
        }

        // Logical operators
        if let anyOf { return JSONSchema(type: .anyOf(.init(anyOf: anyOf))) }
        if let allOf { return JSONSchema(type: .allOf(.init(allOf: allOf))) }
        if let oneOf { return JSONSchema(type: .oneOf(.init(oneOf: oneOf))) }
        if let notSchema { return JSONSchema(type: .not(.init(not: notSchema))) }

        // Type-based schemas
        switch typeValue {
        case "string":
            return JSONSchema(
                type: .string(
                    .init(
                        description: descriptionValue,
                        minLength: minLength,
                        maxLength: maxLength,
                        pattern: pattern
                    )
                )
            )
        case "object":
            return JSONSchema(
                type: .object(
                    .init(
                        description: descriptionValue,
                        properties: properties ?? [:],
                        required: required,
                        additionalProperties: additionalProperties
                    )
                )
            )
        case "array":
            guard let items else {
                throw CodingError.dataCorrupted(
                    debugDescription: "array schema requires 'items'"
                )
            }
            return JSONSchema(
                type: .array(
                    .init(
                        description: descriptionValue,
                        items: items,
                        minItems: minItems,
                        maxItems: maxItems,
                        uniqueItems: uniqueItems
                    )
                )
            )
        case "integer":
            var intMin: Int?
            var intMax: Int?
            if case .number(let n)? = minimum { intMin = n.as(Int.self) }
            if case .number(let n)? = maximum { intMax = n.as(Int.self) }
            return JSONSchema(
                type: .integer(
                    .init(description: descriptionValue, minimum: intMin, maximum: intMax)
                )
            )
        case "number":
            var dblMin: Double?
            var dblMax: Double?
            if case .number(let n)? = minimum { dblMin = n.as(Double.self) }
            if case .number(let n)? = maximum { dblMax = n.as(Double.self) }
            return JSONSchema(
                type: .number(
                    .init(description: descriptionValue, minimum: dblMin, maximum: dblMax)
                )
            )
        case "boolean":
            return JSONSchema(type: .boolean(.init(description: descriptionValue)))
        case "null":
            return JSONSchema(type: .null(.init(description: descriptionValue)))
        case nil:
            throw CodingError.dataCorrupted(
                debugDescription: "Cannot determine JSON Schema type from object keys"
            )
        default:
            throw CodingError.dataCorrupted(
                debugDescription: "Unknown JSON Schema type: \(typeValue!)"
            )
        }
    }
}

// MARK: - visitString for SchemaVisitor

extension SchemaVisitor {
    func visitString(_ string: String) throws(CodingError.Decoding) -> JSONSchema {
        throw CodingError.dataCorrupted(debugDescription: "string is not a valid JSON Schema")
    }

    func visit(_ float: Float) throws(CodingError.Decoding) -> JSONSchema {
        throw CodingError.dataCorrupted(debugDescription: "number is not a valid JSON Schema")
    }
}
