/// A type-safe Swift representation of JSON Schema.
///
/// `JSONSchema` provides a Swift-native way to define, read, and modify JSON Schema specifications.
/// This library focuses on schema representation and manipulation rather than validation.
///
/// ## Features
/// - Type-safe schema construction
/// - Full `Codable` support for reading/writing JSON Schema files
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
/// // Decode from JSON
/// let schemaJSON = """
/// {
///     "type": "object",
///     "properties": {
///         "name": { "type": "string" }
///     }
/// }
/// """
/// let schema = try JSONDecoder().decode(JSONSchema.self, from: schemaJSON.data(using: .utf8)!)
///
/// // Encode to JSON
/// let encoded = try JSONEncoder().encode(schema)
/// ```
public struct JSONSchema: Codable, Equatable, Sendable {
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
        case .enum: return EnumSchema._Type.`enum`.rawValue
        case .array: return ArraySchema._Type.array.rawValue
        case .integer: return IntegerSchema._Type.integer.rawValue
        case .number: return NumberSchema._Type.number.rawValue
        case .boolean: return BooleanSchema._Type.boolean.rawValue
        case .null: return NullSchema._Type.null.rawValue
        case .true, .false, .anyOf, .allOf, .oneOf, .not: return nil  // These do not have a type property in the schema
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
        case .true, .false, .anyOf, .allOf, .oneOf, .not: return nil  // These do not have a description property in the schema
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

    public init(from decoder: any Decoder) throws {

        let container = try decoder.singleValueContainer()
        var errors: [any Error] = []
        do {
            self._type = .string(try container.decode(StringSchema.self))
            return
        } catch { errors.append(error) }

        do {
            self._type = .object(try container.decode(ObjectSchema.self))
            return
        } catch { errors.append(error) }

        do {
            self._type = .enum(try container.decode(EnumSchema.self))
            return
        } catch { errors.append(error) }

        do {
            self._type = .array(try container.decode(ArraySchema.self))
            return
        } catch { errors.append(error) }

        do {
            self._type = .integer(try container.decode(IntegerSchema.self))
            return
        } catch { errors.append(error) }

        do {
            self._type = .number(try container.decode(NumberSchema.self))
            return
        } catch { errors.append(error) }

        do {
            self._type = .boolean(try container.decode(BooleanSchema.self))
            return
        } catch { errors.append(error) }

        do {
            self._type = .null(try container.decode(NullSchema.self))
            return
        } catch { errors.append(error) }

        do {
            let booleanValue = try container.decode(Bool.self)
            self._type = booleanValue ? .true : .false
            return
        } catch { errors.append(error) }

        do {
            self._type = .anyOf(try container.decode(AnyOfSchema.self))
            return
        } catch { errors.append(error) }

        do {
            self._type = .allOf(try container.decode(AllOfSchema.self))
            return
        } catch { errors.append(error) }

        do {
            self._type = .oneOf(try container.decode(OneOfSchema.self))
            return
        } catch { errors.append(error) }

        do {
            self._type = .not(try container.decode(NotSchema.self))
            return
        } catch { errors.append(error) }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Unsupported JSON Schema type. Errors: \(errors.map { "\($0)" }.joined(separator: ", "))"
        )
    }

    public func encode(to encoder: any Encoder) throws {
        switch _type {
        case .string(let schema): try schema.encode(to: encoder)
        case .object(let schema): try schema.encode(to: encoder)
        case .enum(let schema): try schema.encode(to: encoder)
        case .array(let schema): try schema.encode(to: encoder)
        case .integer(let schema): try schema.encode(to: encoder)
        case .number(let schema): try schema.encode(to: encoder)
        case .boolean(let schema): try schema.encode(to: encoder)
        case .null(let schema): try schema.encode(to: encoder)
        case .true:
            var container = encoder.singleValueContainer()
            try container.encode(true)
        case .false:
            var container = encoder.singleValueContainer()
            try container.encode(false)
        case .anyOf(let schema): try schema.encode(to: encoder)
        case .allOf(let schema): try schema.encode(to: encoder)
        case .oneOf(let schema): try schema.encode(to: encoder)
        case .not(let schema): try schema.encode(to: encoder)
        }
    }

    /// Creates a string schema with optional constraints.
    /// - Parameters:
    ///   - title: Short title for the schema
    ///   - description: Human-readable description of the schema
    ///   - default: Default string value
    ///   - examples: Array of example values
    ///   - const: Single allowed value (makes this an enum with one value)
    ///   - minLength: Minimum string length
    ///   - maxLength: Maximum string length
    ///   - pattern: Regular expression pattern the string must match
    ///   - format: Format constraint (e.g., "email", "date", "uri")
    /// - Returns: A new string schema
    public static func string(
        title: String? = nil,
        description: String? = nil,
        default: String? = nil,
        examples: [String]? = nil,
        const: String? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        pattern: String? = nil,
        format: String? = nil
    ) -> Self {
        JSONSchema(
            type: .string(
                .init(
                    title: title,
                    description: description,
                    default: `default`,
                    examples: examples,
                    const: const,
                    minLength: minLength,
                    maxLength: maxLength,
                    pattern: pattern,
                    format: format
                )
            )
        )
    }

    /// Creates an object schema with property definitions.
    /// - Parameters:
    ///   - title: Short title for the schema
    ///   - description: Human-readable description of the schema
    ///   - properties: Dictionary of property names to their schemas
    ///   - required: Array of property names that must be present
    ///   - additionalProperties: Schema for properties not explicitly defined
    /// - Returns: A new object schema
    public static func object(
        title: String? = nil,
        description: String? = nil,
        properties: [String: JSONSchema],
        required: [String]? = nil,
        additionalProperties: JSONSchema? = nil
    ) -> Self {
        JSONSchema(
            type: .object(
                .init(
                    title: title,
                    description: description,
                    properties: properties,
                    required: required,
                    additionalProperties: additionalProperties
                )
            )
        )
    }

    /// Creates an enum schema with a fixed set of allowed string values.
    /// - Parameters:
    ///   - title: Short title for the schema
    ///   - description: Human-readable description of the schema
    ///   - values: Array of allowed string values
    /// - Returns: A new enum schema
    public static func `enum`(
        title: String? = nil,
        description: String? = nil,
        values: [String]
    ) -> Self {
        JSONSchema(type: .enum(.init(title: title, description: description, values: values)))
    }

    /// Creates an array schema with item type and constraints.
    /// - Parameters:
    ///   - title: Short title for the schema
    ///   - description: Human-readable description of the schema
    ///   - items: Schema that all array items must conform to
    ///   - minItems: Minimum number of items
    ///   - maxItems: Maximum number of items
    ///   - uniqueItems: Whether all items must be unique
    /// - Returns: A new array schema
    public static func array(
        title: String? = nil,
        description: String? = nil,
        items: JSONSchema,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) -> Self {
        JSONSchema(
            type: .array(
                .init(
                    title: title,
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
    /// - Parameters:
    ///   - title: Short title for the schema
    ///   - description: Human-readable description of the schema
    ///   - default: Default integer value
    ///   - examples: Array of example values
    ///   - const: Single allowed value
    ///   - minimum: Minimum allowed value (inclusive)
    ///   - maximum: Maximum allowed value (inclusive)
    ///   - exclusiveMinimum: Minimum allowed value (exclusive)
    ///   - exclusiveMaximum: Maximum allowed value (exclusive)
    ///   - multipleOf: Value must be a multiple of this number
    /// - Returns: A new integer schema
    public static func integer(
        title: String? = nil,
        description: String? = nil,
        default: Int? = nil,
        examples: [Int]? = nil,
        const: Int? = nil,
        minimum: Int? = nil,
        maximum: Int? = nil,
        exclusiveMinimum: Int? = nil,
        exclusiveMaximum: Int? = nil,
        multipleOf: Int? = nil
    ) -> Self {
        JSONSchema(
            type: .integer(
                .init(
                    title: title,
                    description: description,
                    default: `default`,
                    examples: examples,
                    const: const,
                    minimum: minimum,
                    maximum: maximum,
                    exclusiveMinimum: exclusiveMinimum,
                    exclusiveMaximum: exclusiveMaximum,
                    multipleOf: multipleOf
                )
            )
        )
    }

    /// Creates a number schema for floating-point values with optional range constraints.
    /// - Parameters:
    ///   - title: Short title for the schema
    ///   - description: Human-readable description of the schema
    ///   - default: Default numeric value
    ///   - examples: Array of example values
    ///   - const: Single allowed value
    ///   - minimum: Minimum allowed value (inclusive)
    ///   - maximum: Maximum allowed value (inclusive)
    ///   - exclusiveMinimum: Minimum allowed value (exclusive)
    ///   - exclusiveMaximum: Maximum allowed value (exclusive)
    ///   - multipleOf: Value must be a multiple of this number
    /// - Returns: A new number schema
    public static func number(
        title: String? = nil,
        description: String? = nil,
        default: Double? = nil,
        examples: [Double]? = nil,
        const: Double? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil,
        exclusiveMinimum: Double? = nil,
        exclusiveMaximum: Double? = nil,
        multipleOf: Double? = nil
    ) -> Self {
        JSONSchema(
            type: .number(
                .init(
                    title: title,
                    description: description,
                    default: `default`,
                    examples: examples,
                    const: const,
                    minimum: minimum,
                    maximum: maximum,
                    exclusiveMinimum: exclusiveMinimum,
                    exclusiveMaximum: exclusiveMaximum,
                    multipleOf: multipleOf
                )
            )
        )
    }

    /// Creates a boolean schema that matches a boolean value.
    /// - Parameters:
    ///   - title: Short title for the schema
    ///   - description: Human-readable description of the schema
    ///   - default: Default boolean value
    ///   - examples: Array of example values
    ///   - const: Single allowed value
    /// - Returns: A new boolean schema.
    public static func boolean(
        title: String? = nil,
        description: String? = nil,
        default: Bool? = nil,
        examples: [Bool]? = nil,
        const: Bool? = nil
    ) -> Self {
        JSONSchema(
            type: .boolean(
                .init(
                    title: title,
                    description: description,
                    default: `default`,
                    examples: examples,
                    const: const
                )
            )
        )
    }

    /// Creates a null schema that matches a null value.
    /// - Parameters:
    ///   - title: Short title for the schema
    ///   - description: Human-readable description of the schema
    /// - Returns: A new null schema.
    public static func null(title: String? = nil, description: String? = nil) -> Self {
        JSONSchema(type: .null(.init(title: title, description: description)))
    }

    /// Creates a schema that matches if any of the provided schemas match.
    /// - Parameter schemas: Array of schemas where at least one must match
    /// - Returns: A new anyOf schema
    public static func anyOf(_ schemas: [JSONSchema]) -> Self { JSONSchema(type: .anyOf(.init(anyOf: schemas))) }

    /// Creates a schema that matches only if all of the provided schemas match.
    /// - Parameter schemas: Array of schemas that must all match
    /// - Returns: A new allOf schema
    public static func allOf(_ schemas: [JSONSchema]) -> Self { JSONSchema(type: .allOf(.init(allOf: schemas))) }

    /// Creates a schema that matches exactly one of the provided schemas.
    /// - Parameter schemas: Array of schemas where exactly one must match
    /// - Returns: A new oneOf schema
    public static func oneOf(_ schemas: [JSONSchema]) -> Self { JSONSchema(type: .oneOf(.init(oneOf: schemas))) }

    /// Creates a schema that inverts the matching logic of another schema.
    /// - Parameter schema: Schema whose matching logic should be inverted
    /// - Returns: A new not schema
    public static func not(_ schema: JSONSchema) -> Self { JSONSchema(type: .not(.init(not: schema))) }

    /// A boolean schema that always matches (allows any value).
    public static var `true`: Self { JSONSchema(type: .true) }

    /// A boolean schema that never matches (rejects all values).
    public static var `false`: Self { JSONSchema(type: .false) }

    /// Schema for string values with optional validation constraints.
    public struct StringSchema: Codable, Equatable, Sendable {
        public enum _Type: String, Codable, Sendable { case string = "string" }

        public var type: _Type = .string
        public var title: String?
        public var description: String?
        public var `default`: String?
        public var examples: [String]?
        public var const: String?
        public var minLength: Int?
        public var maxLength: Int?
        public var pattern: String?
        public var format: String?

        /// Initializes a new string schema with optional constraints.
        /// - Parameters:
        ///   - title: Short title for the schema
        ///   - description: Human-readable description of the schema
        ///   - default: Default string value
        ///   - examples: Array of example values
        ///   - const: Single allowed value (makes this an enum with one value)
        ///   - minLength: Minimum string length
        ///   - maxLength: Maximum string length
        ///   - pattern: Regular expression pattern the string must match
        ///   - format: Format constraint (e.g., "email", "date", "uri")
        /// - Returns: A new string schema
        public init(
            title: String? = nil,
            description: String? = nil,
            default: String? = nil,
            examples: [String]? = nil,
            const: String? = nil,
            minLength: Int? = nil,
            maxLength: Int? = nil,
            pattern: String? = nil,
            format: String? = nil
        ) {
            self.title = title
            self.description = description
            self.default = `default`
            self.examples = examples
            self.const = const
            self.minLength = minLength
            self.maxLength = maxLength
            self.pattern = pattern
            self.format = format
        }
    }

    /// Schema for object values with property definitions and validation rules.
    public struct ObjectSchema: Codable, Equatable, Sendable {
        public enum _Type: String, Codable, Sendable { case object = "object" }
        public var type: _Type = .object
        public var title: String?
        public var description: String?
        public var properties: [String: JSONSchema]
        public var required: [String]?
        public var additionalProperties: JSONSchema?

        /// Initializes a new object schema with property definitions.
        /// - Parameters:
        ///   - title: Short title for the schema
        ///   - description: Human-readable description of the schema
        ///   - properties: Dictionary of property names to their schemas
        ///   - required: Array of property names that must be present
        ///   - additionalProperties: Schema for properties not explicitly defined
        public init(
            title: String? = nil,
            description: String? = nil,
            properties: [String: JSONSchema],
            required: [String]? = nil,
            additionalProperties: JSONSchema? = nil
        ) {
            self.title = title
            self.description = description
            self.properties = properties
            self.required = required
            self.additionalProperties = additionalProperties
        }
    }

    /// Schema for enumerated string values restricted to a specific set.
    public struct EnumSchema: Codable, Equatable, Sendable {
        public enum _Type: String, Codable, Sendable { case `enum` = "enum" }
        public var type: _Type = .enum
        public var title: String?
        public var description: String?
        public var values: [String]

        /// Initializes a new enum schema with a fixed set of allowed values.
        /// - Parameters:
        ///   - title: Short title for the schema
        ///   - description: Human-readable description of the schema
        ///   - values: Array of allowed string values
        public init(title: String? = nil, description: String? = nil, values: [String]) {
            self.title = title
            self.description = description
            self.values = values
        }
    }

    /// Schema for array values with item type and validation constraints.
    public struct ArraySchema: Codable, Equatable, Sendable {
        public enum _Type: String, Codable, Sendable { case array = "array" }
        public var type: _Type = .array
        public var title: String?
        public var description: String?
        public var items: JSONSchema
        public var minItems: Int?
        public var maxItems: Int?
        public var uniqueItems: Bool?

        /// Initializes a new array schema with item type and constraints.
        /// - Parameters:
        ///   - title: Short title for the schema
        ///   - description: Human-readable description of the schema
        ///   - items: Schema that all array items must conform to
        ///   - minItems: Minimum number of items
        ///   - maxItems: Maximum number of items
        ///   - uniqueItems: Whether all items must be unique
        public init(
            title: String? = nil,
            description: String? = nil,
            items: JSONSchema,
            minItems: Int? = nil,
            maxItems: Int? = nil,
            uniqueItems: Bool? = nil
        ) {
            self.title = title
            self.description = description
            self.items = items
            self.minItems = minItems
            self.maxItems = maxItems
            self.uniqueItems = uniqueItems
        }
    }

    /// Schema for integer values with optional range constraints.
    public struct IntegerSchema: Codable, Equatable, Sendable {
        public enum _Type: String, Codable, Sendable { case integer = "integer" }
        public var type: _Type = .integer
        public var title: String?
        public var description: String?
        public var `default`: Int?
        public var examples: [Int]?
        public var const: Int?
        public var minimum: Int?
        public var maximum: Int?
        public var exclusiveMinimum: Int?
        public var exclusiveMaximum: Int?
        public var multipleOf: Int?

        /// Initializes a new integer schema with optional range constraints.
        /// - Parameters:
        ///   - title: Short title for the schema
        ///   - description: Human-readable description of the schema
        ///   - default: Default integer value
        ///   - examples: Array of example values
        ///   - const: Single allowed value
        ///   - minimum: Minimum allowed value (inclusive)
        ///   - maximum: Maximum allowed value (inclusive)
        ///   - exclusiveMinimum: Minimum allowed value (exclusive)
        ///   - exclusiveMaximum: Maximum allowed value (exclusive)
        ///   - multipleOf: Value must be a multiple of this number
        public init(
            title: String? = nil,
            description: String? = nil,
            default: Int? = nil,
            examples: [Int]? = nil,
            const: Int? = nil,
            minimum: Int? = nil,
            maximum: Int? = nil,
            exclusiveMinimum: Int? = nil,
            exclusiveMaximum: Int? = nil,
            multipleOf: Int? = nil
        ) {
            self.title = title
            self.description = description
            self.default = `default`
            self.examples = examples
            self.const = const
            self.minimum = minimum
            self.maximum = maximum
            self.exclusiveMinimum = exclusiveMinimum
            self.exclusiveMaximum = exclusiveMaximum
            self.multipleOf = multipleOf
        }
    }

    /// Schema for numeric values (floating point) with optional range constraints.
    public struct NumberSchema: Codable, Equatable, Sendable {
        public enum _Type: String, Codable, Sendable { case number = "number" }
        public var type: _Type = .number
        public var title: String?
        public var description: String?
        public var `default`: Double?
        public var examples: [Double]?
        public var const: Double?
        public var minimum: Double?
        public var maximum: Double?
        public var exclusiveMinimum: Double?
        public var exclusiveMaximum: Double?
        public var multipleOf: Double?

        /// Initializes a new number schema with optional range constraints.
        /// - Parameters:
        ///   - title: Short title for the schema
        ///   - description: Human-readable description of the schema
        ///   - default: Default numeric value
        ///   - examples: Array of example values
        ///   - const: Single allowed value
        ///   - minimum: Minimum allowed value (inclusive)
        ///   - maximum: Maximum allowed value (inclusive)
        ///   - exclusiveMinimum: Minimum allowed value (exclusive)
        ///   - exclusiveMaximum: Maximum allowed value (exclusive)
        ///   - multipleOf: Value must be a multiple of this number
        public init(
            title: String? = nil,
            description: String? = nil,
            default: Double? = nil,
            examples: [Double]? = nil,
            const: Double? = nil,
            minimum: Double? = nil,
            maximum: Double? = nil,
            exclusiveMinimum: Double? = nil,
            exclusiveMaximum: Double? = nil,
            multipleOf: Double? = nil
        ) {
            self.title = title
            self.description = description
            self.default = `default`
            self.examples = examples
            self.const = const
            self.minimum = minimum
            self.maximum = maximum
            self.exclusiveMinimum = exclusiveMinimum
            self.exclusiveMaximum = exclusiveMaximum
            self.multipleOf = multipleOf
        }
    }

    /// Schema for boolean values.
    public struct BooleanSchema: Codable, Equatable, Sendable {
        public enum _Type: String, Codable, Sendable { case boolean = "boolean" }
        public var type: _Type = .boolean
        public var title: String?
        public var description: String?
        public var `default`: Bool?
        public var examples: [Bool]?
        public var const: Bool?

        /// Initializes a new boolean schema.
        /// - Parameters:
        ///   - title: Short title for the schema
        ///   - description: Human-readable description of the schema
        ///   - default: Default boolean value
        ///   - examples: Array of example values
        ///   - const: Single allowed value
        public init(
            title: String? = nil,
            description: String? = nil,
            default: Bool? = nil,
            examples: [Bool]? = nil,
            const: Bool? = nil
        ) {
            self.title = title
            self.description = description
            self.default = `default`
            self.examples = examples
            self.const = const
        }
    }

    /// Schema for null values.
    public struct NullSchema: Codable, Equatable, Sendable {
        public enum _Type: String, Codable, Sendable { case null = "null" }
        public var type: _Type = .null
        public var title: String?
        public var description: String?

        /// Initializes a new null schema.
        /// - Parameters:
        ///   - title: Short title for the schema
        ///   - description: Human-readable description of the schema
        public init(
            title: String? = nil,
            description: String? = nil
        ) {
            self.title = title
            self.description = description
        }
    }

    /// Schema that matches if any of the provided schemas match.
    public struct AnyOfSchema: Codable, Equatable, Sendable {
        public var anyOf: [JSONSchema]

        /// Initializes a new anyOf schema.
        /// - Parameter anyOf: Array of schemas where at least one must match
        public init(anyOf: [JSONSchema]) { self.anyOf = anyOf }
    }

    /// Schema that matches only if all of the provided schemas match.
    public struct AllOfSchema: Codable, Equatable, Sendable {
        public var allOf: [JSONSchema]

        /// Initializes a new allOf schema.
        /// - Parameter allOf: Array of schemas that must all match
        public init(allOf: [JSONSchema]) { self.allOf = allOf }
    }

    /// Schema that matches exactly one of the provided schemas.
    public struct OneOfSchema: Codable, Equatable, Sendable {
        public var oneOf: [JSONSchema]

        /// Initializes a new oneOf schema.
        /// - Parameter oneOf: Array of schemas where exactly one must match
        public init(oneOf: [JSONSchema]) { self.oneOf = oneOf }
    }

    /// Schema that inverts the matching logic of another schema.
    public struct NotSchema: Codable, Equatable, Sendable {
        public var not: JSONSchema

        /// Initializes a new not schema.
        /// - Parameter not: Schema whose matching logic should be inverted
        public init(not: JSONSchema) { self.not = not }
    }
}
