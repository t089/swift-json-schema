


public struct JSONValue: JSONValueConvertible, Codable, Equatable, Sendable {
    let value: Kind

    init(_ value: Kind) {
        self.value = value
    }

    public init(_ jsonValue: JSONValue) throws {
        self.value = jsonValue.value
    }

    public var jsonValue: JSONValue {
        return self
    }

    public init(_ value: some ConvertibleToJSONValue) {
        self = value.jsonValue
    }

    public init(values: [any ConvertibleToJSONValue]) {
        self.value = .array(values.map { $0.jsonValue.value })
    }

    public init(object: [String: any ConvertibleToJSONValue]) {
        self.value = .object(object.mapValues { $0.jsonValue.value })
    }

    public func value<Value>(_ type: Value.Type) throws -> Value where Value: ConvertibleFromJSONValue {
        return try Value(self)
    }

    public func value<Value>(for property: String, as type: Value.Type) throws -> Value where Value: ConvertibleFromJSONValue {
        guard case let .object(object) = self.value, let jsonValue = object[property] else {
            throw JSONValueError(description: "Key '\(property)' not found in JSON object \(self)")
        }
        return try Value(Self(jsonValue))
    }

    public var values: [JSONValue]? {
        switch self.value {
        case .array(let values):
            return values.map { Self($0) }
        default:
            return nil
        }
    }

    public var properties: [String: JSONValue]? {
        switch self.value {
        case .object(let object):
            return object.mapValues { Self($0) }
        default:
            return nil
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(Kind.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.value)
    }
}

public struct JSONValueError: Error, CustomStringConvertible {
    public let description: String

    public init(description: String) {
        self.description = description
    }
}

public protocol ConvertibleFromJSONValue: Sendable {
    init(_ jsonValue: JSONValue) throws
}

public protocol ConvertibleToJSONValue: Sendable {
    var jsonValue: JSONValue { get }
}

public protocol JSONValueConvertible: ConvertibleFromJSONValue, ConvertibleToJSONValue {}


extension Bool: JSONValueConvertible {
    public var jsonValue: JSONValue {
        return JSONValue(.boolean(self))
    }

    public init(_ jsonValue: JSONValue) throws {
        guard case let .boolean(value) = jsonValue.value else {
            throw JSONValueError(description: "Expected boolean value, got \(jsonValue)")
        }
        self = value
    }
}

extension String: JSONValueConvertible {
    public var jsonValue: JSONValue {
        return JSONValue(.string(self))
    }

    public init(_ jsonValue: JSONValue) throws {
        guard case let .string(value) = jsonValue.value else {
            throw JSONValueError(description: "Expected string value, got \(jsonValue)")
        }
        self = value
    }
}

extension Int: JSONValueConvertible {
    public var jsonValue: JSONValue {
        return JSONValue(.integer(self))
    }

    public init(_ jsonValue: JSONValue) throws {
        guard case let .integer(value) = jsonValue.value else {
            throw JSONValueError(description: "Expected integer value, got \(jsonValue)")
        }
        self = value
    }
}

extension Double: JSONValueConvertible {
    public var jsonValue: JSONValue {
        return JSONValue(.number(self))
    }

    public init(_ jsonValue: JSONValue) throws {
        guard case let .number(value) = jsonValue.value else {
            throw JSONValueError(description: "Expected number value, got \(jsonValue)")
        }
        self = value
    }
}

extension Array: ConvertibleFromJSONValue where Element: ConvertibleFromJSONValue {
    public init(_ jsonValue: JSONValue) throws {
        guard case let .array(values) = jsonValue.value else {
            throw JSONValueError(description: "Expected array value, got \(jsonValue)")
        }
        self = try values.map { try Element(JSONValue($0)) }
    }
}

extension Array: ConvertibleToJSONValue where Element: ConvertibleToJSONValue {
    public var jsonValue: JSONValue {
        return JSONValue(.array(self.map { $0.jsonValue.value }))
    }
}

extension JSONValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.value = .null
    }
}

extension JSONValue {
    enum Kind {
        case string(String)
        case integer(Int)
        case number(Double)
        case boolean(Bool)
        case null
        case array([Kind])
        case object([String: Kind])
    }
}

extension JSONValue.Kind: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let boolean = try? container.decode(Bool.self) {
            self = .boolean(boolean)
        } else if let integer = try? container.decode(Int.self) {
            self = .integer(integer)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number) 
        } else if container.decodeNil() {
            self = .null
        } else if let array = try? container.decode([JSONValue.Kind].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue.Kind].self) {
            self = .object(object)
        } else {
            throw DecodingError.typeMismatch(JSONValue.Kind.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value type"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .integer(let value):
            try container.encode(value)
        case .boolean(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}

extension JSONValue.Kind: Equatable {
    public static func ==(lhs: JSONValue.Kind, rhs: JSONValue.Kind) -> Bool {
        switch (lhs, rhs) {
        case (.string(let l), .string(let r)):
            return l == r
        case (.integer(let l), .integer(let r)):
            return l == r
        case (.number(let l), .number(let r)):
            return l == r
        case (.boolean(let l), .boolean(let r)):
            return l == r
        case (.null, .null):
            return true
        case (.array(let l), .array(let r)):
            return l == r
        case (.object(let l), .object(let r)):
            return l == r
        default:
            return false
        }
    }
}