@_exported import JSONMacros

/// A type-safe Swift representation of JSON Schema.
public struct JSONSchema: Equatable, Sendable {
    /// Internal representation of the various schema types.
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

    public var type: String? {
        switch _type {
        case .string: return "string"
        case .object: return "object"
        case .enum(let enumSchema): return enumSchema.type
        case .array: return "array"
        case .integer: return "integer"
        case .number: return "number"
        case .boolean: return "boolean"
        case .null: return "null"
        case .true, .false, .anyOf, .allOf, .oneOf, .not: return nil
        }
    }

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

    public var string: StringSchema? {
        if case .string(let schema) = _type { return schema }
        return nil
    }

    public var object: ObjectSchema? {
        if case .object(let schema) = _type { return schema }
        return nil
    }

    public var `enum`: EnumSchema? {
        if case .enum(let schema) = _type { return schema }
        return nil
    }

    public var array: ArraySchema? {
        if case .array(let schema) = _type { return schema }
        return nil
    }

    public var integer: IntegerSchema? {
        if case .integer(let schema) = _type { return schema }
        return nil
    }

    public var number: NumberSchema? {
        if case .number(let schema) = _type { return schema }
        return nil
    }

    public var boolean: BooleanSchema? {
        if case .boolean = _type { return nil }
        return BooleanSchema()
    }

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

    public var isTrue: Bool {
        if case .true = _type { return true }
        return false
    }

    public var isFalse: Bool {
        if case .false = _type { return true }
        return false
    }

    init(type: Internal) { self._type = type }

    // MARK: - Static constructors

    public static func string(
        description: String? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        pattern: String? = nil
    ) -> Self {
        JSONSchema(
            type: .string(
                .init(description: description, minLength: minLength, maxLength: maxLength, pattern: pattern)
            )
        )
    }

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

    public static func `enum`(
        description: String? = nil,
        values: [any ConvertibleToJSONValue] = []
    ) -> Self {
        JSONSchema(type: .enum(.init(description: description, values: values)))
    }

    public static func `enum`(
        description: String? = nil,
        values: [String] = []
    ) -> Self {
        JSONSchema(type: .enum(.string(description: description, values: values)))
    }

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

    public static func integer(
        description: String? = nil,
        minimum: Int? = nil,
        maximum: Int? = nil
    ) -> Self {
        JSONSchema(type: .integer(.init(description: description, minimum: minimum, maximum: maximum)))
    }

    public static func number(
        description: String? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil
    ) -> Self {
        JSONSchema(type: .number(.init(description: description, minimum: minimum, maximum: maximum)))
    }

    public static func boolean(description: String? = nil) -> Self {
        JSONSchema(type: .boolean(.init(description: description)))
    }

    public static func null(description: String? = nil) -> Self {
        JSONSchema(type: .null(.init(description: description)))
    }

    public static func anyOf(_ schemas: [JSONSchema]) -> Self {
        JSONSchema(type: .anyOf(.init(anyOf: schemas)))
    }

    public static func allOf(_ schemas: [JSONSchema]) -> Self {
        JSONSchema(type: .allOf(.init(allOf: schemas)))
    }

    public static func oneOf(_ schemas: [JSONSchema]) -> Self {
        JSONSchema(type: .oneOf(.init(oneOf: schemas)))
    }

    public static func not(_ schema: JSONSchema) -> Self {
        JSONSchema(type: .not(.init(not: schema)))
    }

    public static var `true`: Self { JSONSchema(type: .true) }
    public static var `false`: Self { JSONSchema(type: .false) }

    // MARK: - Sub-schema types

    @JSONCodable
    public struct StringSchema: Equatable, Sendable {
        public enum _Type: String, Sendable, JSONDecodable, JSONEncodable { case string = "string" }

        public var type: _Type = .string
        public var description: String?
        public var minLength: Int?
        public var maxLength: Int?
        public var pattern: String?

        public init(
            description: String? = nil,
            minLength: Int? = nil,
            maxLength: Int? = nil,
            pattern: String? = nil
        ) {
            self.description = description
            self.minLength = minLength
            self.maxLength = maxLength
            self.pattern = pattern
        }
    }

    @JSONCodable
    public struct ObjectSchema: Equatable, Sendable {
        public enum _Type: String, Sendable, JSONDecodable, JSONEncodable { case object = "object" }
        public var type: _Type = .object
        public var description: String?
        public var properties: [String: JSONSchema]
        public var required: [String]?
        public var additionalProperties: JSONSchema?

        public init(
            description: String? = nil,
            properties: [String: JSONSchema],
            required: [String]? = nil,
            additionalProperties: JSONSchema? = nil
        ) {
            self.description = description
            self.properties = properties
            self.required = required
            self.additionalProperties = additionalProperties
        }
    }

    @JSONCodable
    public struct EnumSchema: Equatable, Sendable {
        public var type: String?
        public var description: String?
        @JSONKey("enum")
        public var values: [JSONValue]

        public init(description: String? = nil, values: [any ConvertibleToJSONValue], type: String? = nil) {
            self.description = description
            self.values = values.map { $0.jsonValue }
            self.type = type
        }

        public static func string(description: String? = nil, values: [String]) -> EnumSchema {
            return EnumSchema(description: description, values: values, type: "string")
        }
    }

    @JSONCodable
    public struct ArraySchema: Equatable, Sendable {
        public enum _Type: String, Sendable, JSONDecodable, JSONEncodable { case array = "array" }
        public var type: _Type = .array
        public var description: String?
        public var items: JSONSchema
        public var minItems: Int?
        public var maxItems: Int?
        public var uniqueItems: Bool?

        public init(
            description: String? = nil,
            items: JSONSchema,
            minItems: Int? = nil,
            maxItems: Int? = nil,
            uniqueItems: Bool? = nil
        ) {
            self.description = description
            self.items = items
            self.minItems = minItems
            self.maxItems = maxItems
            self.uniqueItems = uniqueItems
        }
    }

    @JSONCodable
    public struct IntegerSchema: Equatable, Sendable {
        public enum _Type: String, Sendable, JSONDecodable, JSONEncodable {
            case integer = "integer"
        }
        public var type: _Type = .integer
        public var description: String?
        public var minimum: Int?
        public var maximum: Int?

        public init(description: String? = nil, minimum: Int? = nil, maximum: Int? = nil) {
            self.description = description
            self.minimum = minimum
            self.maximum = maximum
        }
    }

    @JSONCodable
    public struct NumberSchema: Equatable, Sendable {
        public enum _Type: String, Sendable, JSONDecodable, JSONEncodable { case number = "number" }
        public var type: _Type = .number
        public var description: String?
        public var minimum: Double?
        public var maximum: Double?

        public init(
            description: String? = nil,
            minimum: Double? = nil,
            maximum: Double? = nil
        ) {
            self.description = description
            self.minimum = minimum
            self.maximum = maximum
        }
    }

    @JSONCodable
    public struct BooleanSchema: Equatable, Sendable {
        public enum _Type: String, Sendable, JSONDecodable, JSONEncodable {
            case boolean = "boolean"
        }
        public var type: _Type = .boolean
        public var description: String?

        public init(description: String? = nil) {
            self.description = description
        }
    }

    @JSONCodable
    public struct NullSchema: Equatable, Sendable {
        public enum _Type: String, Sendable, JSONDecodable, JSONEncodable { case null = "null" }
        public var type: _Type = .null
        public var description: String?

        public init(description: String? = nil) {
            self.description = description
        }
    }

    @JSONCodable
    public struct AnyOfSchema: Equatable, Sendable {
        public var anyOf: [JSONSchema]
        public init(anyOf: [JSONSchema]) { self.anyOf = anyOf }
    }

    @JSONCodable
    public struct AllOfSchema: Equatable, Sendable {
        public var allOf: [JSONSchema]
        public init(allOf: [JSONSchema]) { self.allOf = allOf }
    }

    @JSONCodable
    public struct OneOfSchema: Equatable, Sendable {
        public var oneOf: [JSONSchema]
        public init(oneOf: [JSONSchema]) { self.oneOf = oneOf }
    }

    @JSONCodable
    public struct NotSchema: Equatable, Sendable {
        public var not: JSONSchema
        public init(not: JSONSchema) { self.not = not }
    }
}

// MARK: - JSONSchema manual JSONDecodable/JSONEncodable

extension JSONSchema: JSONDecodable {
    public init(json: borrowing JSON.Node) throws {
        // Boolean schemas
        if case .bool(let b) = copy json {
            self._type = b ? .true : .false
            return
        }

        let object: JSON.Object = try .init(json: json)

        // Look for discriminator fields
        var typeString: String? = nil
        var hasEnumKey = false
        var hasAnyOf = false
        var hasAllOf = false
        var hasOneOf = false
        var hasNot = false

        for field: JSON.FieldDecoder<String> in copy object {
            switch field.key {
            case "type": typeString = try? field.decode()
            case "enum": hasEnumKey = true
            case "anyOf": hasAnyOf = true
            case "allOf": hasAllOf = true
            case "oneOf": hasOneOf = true
            case "not": hasNot = true
            default: break
            }
        }

        // Enum schemas (may or may not have a "type" field)
        if hasEnumKey {
            self._type = .enum(try EnumSchema(json: json))
            return
        }

        // Typed schemas
        if let typeString {
            switch typeString {
            case "string":
                self._type = .string(try StringSchema(json: json))
            case "object":
                self._type = .object(try ObjectSchema(json: json))
            case "array":
                self._type = .array(try ArraySchema(json: json))
            case "integer":
                self._type = .integer(try IntegerSchema(json: json))
            case "number":
                self._type = .number(try NumberSchema(json: json))
            case "boolean":
                self._type = .boolean(try BooleanSchema(json: json))
            case "null":
                self._type = .null(try NullSchema(json: json))
            default:
                throw JSONSchemaError(description: "Unknown schema type: \(typeString)")
            }
            return
        }

        // Logical operators
        if hasAnyOf {
            self._type = .anyOf(try AnyOfSchema(json: json))
            return
        }
        if hasAllOf {
            self._type = .allOf(try AllOfSchema(json: json))
            return
        }
        if hasOneOf {
            self._type = .oneOf(try OneOfSchema(json: json))
            return
        }
        if hasNot {
            self._type = .not(try NotSchema(json: json))
            return
        }

        throw JSONSchemaError(description: "Unable to determine JSON Schema type")
    }
}

extension JSONSchema: JSONEncodable {
    public func encode(to json: inout JSON) {
        switch _type {
        case .string(let schema): schema.encode(to: &json)
        case .object(let schema): schema.encode(to: &json)
        case .enum(let schema): schema.encode(to: &json)
        case .array(let schema): schema.encode(to: &json)
        case .integer(let schema): schema.encode(to: &json)
        case .number(let schema): schema.encode(to: &json)
        case .boolean(let schema): schema.encode(to: &json)
        case .null(let schema): schema.encode(to: &json)
        case .true: true.encode(to: &json)
        case .false: false.encode(to: &json)
        case .anyOf(let schema): schema.encode(to: &json)
        case .allOf(let schema): schema.encode(to: &json)
        case .oneOf(let schema): schema.encode(to: &json)
        case .not(let schema): schema.encode(to: &json)
        }
    }
}

// MARK: - Dictionary JSONEncodable retroactive conformance

extension Dictionary: @retroactive JSONEncodable where Key == String, Value: JSONEncodable {
    public func encode(to json: inout JSON) {
        json(Any.self) { encoder in
            for (key, value) in self {
                encoder[key] = value
            }
        }
    }
}

// MARK: - Error type

struct JSONSchemaError: Error, CustomStringConvertible {
    var description: String
}
