@preconcurrency import JSONMacros

/// `JSONValue` is an alias for `JSONPrimitive` from the NewCodable module.
public typealias JSONValue = JSONPrimitive

extension JSONPrimitive: @retroactive @unchecked Sendable {}

// MARK: - ExpressibleByNilLiteral

extension JSONPrimitive: @retroactive ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

// MARK: - Convenience conversion protocols

public protocol ConvertibleToJSONValue {
    var jsonValue: JSONValue { get }
}

public protocol ConvertibleFromJSONValue {
    init(_ jsonValue: JSONValue) throws
}

public protocol JSONValueConvertible: ConvertibleFromJSONValue, ConvertibleToJSONValue {}

// MARK: - Primitive conformances

extension Bool: JSONValueConvertible {
    public var jsonValue: JSONValue { .bool(self) }

    public init(_ jsonValue: JSONValue) throws {
        guard case .bool(let value) = jsonValue else {
            throw JSONValueError(description: "Expected bool, got \(jsonValue)")
        }
        self = value
    }
}

extension String: JSONValueConvertible {
    public var jsonValue: JSONValue { .string(self) }

    public init(_ jsonValue: JSONValue) throws {
        guard case .string(let value) = jsonValue else {
            throw JSONValueError(description: "Expected string, got \(jsonValue)")
        }
        self = value
    }
}

extension Int: JSONValueConvertible {
    public var jsonValue: JSONValue {
        .number(JSONPrimitive.Number(extendedPrecisionRepresentation: "\(self)"))
    }

    public init(_ jsonValue: JSONValue) throws {
        guard case .number(let num) = jsonValue else {
            throw JSONValueError(description: "Expected number, got \(jsonValue)")
        }
        self = try num[Int.self]
    }
}

extension Double: JSONValueConvertible {
    public var jsonValue: JSONValue {
        .number(JSONPrimitive.Number(extendedPrecisionRepresentation: "\(self)"))
    }

    public init(_ jsonValue: JSONValue) throws {
        guard case .number(let num) = jsonValue else {
            throw JSONValueError(description: "Expected number, got \(jsonValue)")
        }
        self = try num[Double.self]
    }
}

extension JSONPrimitive: JSONValueConvertible {
    public var jsonValue: JSONValue { self }

    public init(_ jsonValue: JSONValue) throws {
        self = jsonValue
    }
}

// MARK: - Array conformances

extension Array: ConvertibleToJSONValue where Element: ConvertibleToJSONValue {
    public var jsonValue: JSONValue {
        .array(self.map { $0.jsonValue })
    }
}

extension Array: ConvertibleFromJSONValue where Element: ConvertibleFromJSONValue {
    public init(_ jsonValue: JSONValue) throws {
        guard case .array(let values) = jsonValue else {
            throw JSONValueError(description: "Expected array, got \(jsonValue)")
        }
        self = try values.map { try Element($0) }
    }
}

// MARK: - Error type

public struct JSONValueError: Error, CustomStringConvertible {
    public var description: String

    public init(description: String) {
        self.description = description
    }
}

// MARK: - Number convenience

extension JSONPrimitive.Number {
    /// Try to extract as Int, returns nil if not representable.
    public func `as`(_ type: Int.Type) -> Int? {
        Int(extendedPrecisionRepresentation)
    }

    /// Try to extract as Double, returns nil if not representable.
    public func `as`(_ type: Double.Type) -> Double? {
        Double(extendedPrecisionRepresentation)
    }
}
