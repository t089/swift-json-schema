import JSONMacros

public struct JSONValue: JSONValueConvertible, Equatable, Sendable {
    var value: Kind

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

    public func value<Value>(_ type: Value.Type) throws -> Value
    where Value: ConvertibleFromJSONValue {
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
}

// MARK: - JSONValue.Kind

extension JSONValue {
    enum Kind: Equatable {
        case string(String)
        case integer(Int)
        case number(Double)
        case boolean(Bool)
        case null
        case array([Kind])
        case object([String: Kind])
    }
}

// MARK: - JSONDecodable / JSONEncodable

extension JSONValue: JSONDecodable {
    public init(json: borrowing JSON.Node) throws {
        switch copy json {
        case .null:
            self.init(.null)
        case .bool(let b):
            self.init(.boolean(b))
        case .number(let n):
            if let i = n.as(Int.self) {
                self.init(.integer(i))
            } else if let d = n.as(Double.self) {
                self.init(.number(d))
            } else {
                throw JSONValueError(description: "Cannot convert JSON number")
            }
        case .string(_):
            self.init(.string(try String.init(json: copy json)))
        case .object(let obj):
            var dict: [String: Kind] = [:]
            for field in obj.fields {
                dict[field.key.rawValue] = try JSONValue(json: field.value).value
            }
            self.init(.object(dict))
        case .array(let arr):
            var values: [Kind] = []
            for element in arr.elements {
                values.append(try JSONValue(json: element).value)
            }
            self.init(.array(values))
        }
    }
}

extension JSONValue: JSONEncodable {
    public func encode(to json: inout JSON) {
        switch self.value {
        case .string(let s):
            s.encode(to: &json)
        case .integer(let i):
            i.encode(to: &json)
        case .number(let d):
            d.encode(to: &json)
        case .boolean(let b):
            b.encode(to: &json)
        case .null:
            Optional<String>.none.encode(to: &json)
        case .array(let arr):
            let values = arr.map { JSONValue($0) }
            values.encode(to: &json)
        case .object(let dict):
            json(Any.self) { encoder in
                for (key, kind) in dict {
                    encoder[key] = JSONValue(kind)
                }
            }
        }
    }
}

// MARK: - ExpressibleByNilLiteral

extension JSONValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.value = .null
    }
}

// MARK: - Error type

public struct JSONValueError: Error, CustomStringConvertible {
    public let description: String

    public init(description: String) {
        self.description = description
    }
}

// MARK: - Protocols

public protocol ConvertibleFromJSONValue: Sendable {
    init(_ jsonValue: JSONValue) throws
}

public protocol ConvertibleToJSONValue: Sendable {
    var jsonValue: JSONValue { get }
}

public protocol JSONValueConvertible: ConvertibleFromJSONValue, ConvertibleToJSONValue {}

// MARK: - Primitive conformances

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
