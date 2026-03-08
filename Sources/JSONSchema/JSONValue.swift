import JSONMacros

#if canImport(FoundationEssentials)
    import FoundationEssentials
#else
    import Foundation
#endif

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

    public func value<Value>(for property: String, as type: Value.Type) throws -> Value
    where Value: ConvertibleFromJSONValue {
        guard case .object(let object) = self.value, let jsonValue = object[property] else {
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

// MARK: - JSONEncodable

extension JSONValue: JSONEncodable {
    public func encode(to encoder: inout JSONDirectEncoder) throws(CodingError.Encoding) {
        try value.encode(to: &encoder)
    }
}

// MARK: - JSONDecodable

extension JSONValue: JSONDecodable {
    public static func decode<D: JSONDecoderProtocol & ~Escapable>(
        from decoder: inout D
    ) throws(CodingError.Decoding) -> Self {
        let kind = try Kind.decode(from: &decoder)
        return JSONValue(kind)
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
        guard case .boolean(let value) = jsonValue.value else {
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
        guard case .string(let value) = jsonValue.value else {
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
        guard case .integer(let value) = jsonValue.value else {
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
        guard case .number(let value) = jsonValue.value else {
            throw JSONValueError(description: "Expected number value, got \(jsonValue)")
        }
        self = value
    }
}

extension Array: ConvertibleFromJSONValue where Element: ConvertibleFromJSONValue {
    public init(_ jsonValue: JSONValue) throws {
        guard case .array(let values) = jsonValue.value else {
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
            throw DecodingError.typeMismatch(
                JSONValue.Kind.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unsupported JSON value type"
                )
            )
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

// MARK: - JSONEncodable for Kind

extension JSONValue.Kind: JSONEncodable {
    func encode(to encoder: inout JSONDirectEncoder) throws(CodingError.Encoding) {
        switch self {
        case .string(let value):
            try encoder.encodeString(value)
        case .integer(let value):
            try encoder.encode(value)
        case .number(let value):
            try encoder.encode(value)
        case .boolean(let value):
            try encoder.encode(value)
        case .null:
            try encoder.encodeNil()
        case .array(let values):
            try encoder.encodeArray { arrayEncoder throws(CodingError.Encoding) in
                for element in values {
                    try arrayEncoder.encodeElement { elementEncoder throws(CodingError.Encoding) in
                        try element.encode(to: &elementEncoder)
                    }
                }
            }
        case .object(let dict):
            try encoder.encodeDictionary { dictEncoder throws(CodingError.Encoding) in
                for (key, value) in dict {
                    try dictEncoder.encode(key: key) { valueEncoder throws(CodingError.Encoding) in
                        try value.encode(to: &valueEncoder)
                    }
                }
            }
        }
    }
}

// MARK: - JSONDecodable for Kind

extension JSONValue.Kind: JSONDecodable {
    static func decode<D: JSONDecoderProtocol & ~Escapable>(
        from decoder: inout D
    ) throws(CodingError.Decoding) -> Self {
        try decoder.decodeAny(KindVisitor())
    }
}

struct KindVisitor: JSONDecodingVisitor {
    typealias DecodedValue = JSONValue.Kind

    var prefersArbitraryPrecisionNumbers: Bool { true }

    func visit(_ bool: Bool) throws(CodingError.Decoding) -> JSONValue.Kind {
        .boolean(bool)
    }

    func visit(_ integer: Int64) throws(CodingError.Decoding) -> JSONValue.Kind {
        .integer(Int(integer))
    }

    func visit(_ integer: UInt64) throws(CodingError.Decoding) -> JSONValue.Kind {
        .integer(Int(integer))
    }

    func visit(_ double: Double) throws(CodingError.Decoding) -> JSONValue.Kind {
        .number(double)
    }

    func visit(_ float: Float) throws(CodingError.Decoding) -> JSONValue.Kind {
        .number(Double(float))
    }

    func visitUTF8Bytes(_ buffer: UTF8Span) throws(CodingError.Decoding) -> JSONValue.Kind {
        .string(String(copying: buffer))
    }

    func visitString(_ string: String) throws(CodingError.Decoding) -> JSONValue.Kind {
        .string(string)
    }

    func visitNone() throws(CodingError.Decoding) -> JSONValue.Kind {
        .null
    }

    func visit(decoder: inout some JSONArrayDecoder & ~Escapable) throws(CodingError.Decoding)
        -> JSONValue.Kind
    {
        var elements: [JSONValue.Kind] = []
        try decoder.decodeEachElement { elementDecoder throws(CodingError.Decoding) in
            let element = try elementDecoder.decodeAny(KindVisitor())
            elements.append(element)
        }
        return .array(elements)
    }

    func visit(decoder: inout some JSONDictionaryDecoder & ~Escapable) throws(CodingError.Decoding)
        -> JSONValue.Kind
    {
        var dict: [String: JSONValue.Kind] = [:]
        try decoder.decodeEachKeyAndValue { key, valueDecoder throws(CodingError.Decoding) -> Bool in
            let value = try valueDecoder.decodeAny(KindVisitor())
            dict[key] = value
            return false
        }
        return .object(dict)
    }

    func visitArbitraryPrecisionNumber(_ span: UTF8Span) throws(CodingError.Decoding)
        -> JSONValue.Kind
    {
        let str = String(copying: span)
        if let intVal = Int(str) {
            return .integer(intVal)
        }
        if let doubleVal = Double(str) {
            return .number(doubleVal)
        }
        throw CodingError.dataCorrupted(debugDescription: "Cannot parse number: \(str)")
    }

    func visitArbitraryPrecisionNumber(_ string: String) throws(CodingError.Decoding)
        -> JSONValue.Kind
    {
        if let intVal = Int(string) {
            return .integer(intVal)
        }
        if let doubleVal = Double(string) {
            return .number(doubleVal)
        }
        throw CodingError.dataCorrupted(debugDescription: "Cannot parse number: \(string)")
    }
}

extension JSONValue.Kind: Equatable {
    public static func == (lhs: JSONValue.Kind, rhs: JSONValue.Kind) -> Bool {
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
