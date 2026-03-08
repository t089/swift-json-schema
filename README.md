# swift-json-schema

A type-safe Swift library for defining, reading, and modifying JSON Schema specifications.

## Overview

JSONSchema provides a native Swift representation of JSON Schema, allowing you to:
- Define schemas programmatically
- Read and parse existing JSON Schema files
- Modify and transform schemas
- Full `Codable` support for seamless JSON serialization
- High-performance encoding/decoding via [NewCodable](https://forums.swift.org/t/new-codable-prototype-available-for-feedback/85186) using [swift-json-macros](https://github.com/t089/swift-json-macros)

> **Note**: This library focuses on schema representation and manipulation. It does not currently provide validation functionality.

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/t089/swift-json-schema.git", from: "0.1.0")
]
```

> **Note**: The `new-codable` branch requires Swift 6.3+ (snapshot) and depends on the experimental `new-codable` branch of `swift-foundation`.

## Usage

### Basic Schema Definition

```swift
import JSONSchema

// Simple string schema
let nameSchema = JSONSchema.string(
    description: "User's full name",
    minLength: 1,
    maxLength: 100
)

// Object schema with properties
let userSchema = JSONSchema.object(
    description: "User profile",
    properties: [
        "name": .string(minLength: 1),
        "age": .integer(minimum: 0, maximum: 150),
        "email": .string(pattern: "^[\\w._%+-]+@[\\w.-]+\\.[A-Za-z]{2,}$"),
        "roles": .array(items: .string())
    ],
    required: ["name", "email"]
)
```

### Working with Complex Schemas

```swift
// Enum schema
let statusSchema = JSONSchema.enum(
    description: "Order status",
    values: ["pending", "processing", "shipped", "delivered"]
)

// Array schema with constraints
let tagsSchema = JSONSchema.array(
    description: "List of tags",
    items: .string(minLength: 1),
    minItems: 1,
    maxItems: 10,
    uniqueItems: true
)

// Using logical operators
let paymentSchema = JSONSchema.oneOf([
    .object(properties: ["type": .enum(values: ["credit_card"]), "card_number": .string()]),
    .object(properties: ["type": .enum(values: ["paypal"]), "email": .string()]),
    .object(properties: ["type": .enum(values: ["bitcoin"]), "wallet_address": .string()])
])
```

### Reading and Writing JSON Schema

#### Legacy Codable

```swift
import Foundation

let schemaJSON = """
{
    "type": "object",
    "properties": {
        "name": { "type": "string", "minLength": 1 },
        "age": { "type": "integer", "minimum": 0 }
    },
    "required": ["name"]
}
"""

let schema = try JSONDecoder().decode(JSONSchema.self, from: Data(schemaJSON.utf8))

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let encoded = try encoder.encode(schema)
print(String(data: encoded, encoding: .utf8)!)
```

#### NewCodable (high-performance)

```swift
import JSONSchema
import NewCodable

let schemaJSON = """
{
    "type": "object",
    "properties": {
        "name": { "type": "string", "minLength": 1 },
        "age": { "type": "integer", "minimum": 0 }
    },
    "required": ["name"]
}
"""

let schema = try NewJSONDecoder().decode(JSONSchema.self, from: Data(schemaJSON.utf8))

let encoded = try NewJSONEncoder().encode(schema)
print(String(decoding: encoded, as: UTF8.self))
```

## Supported Schema Types

### Primitive Types
- `string` - Text values with optional length and pattern constraints
- `number` - Floating-point numbers with optional range constraints
- `integer` - Integer values with optional range constraints
- `boolean` - True/false values
- `null` - Null values

### Composite Types
- `object` - Objects with defined properties
- `array` - Arrays with item type specifications

### Special Types
- `enum` - Values restricted to a specific set (strings, numbers, or mixed)

### Logical Operators
- `anyOf` - Matches if any of the provided schemas match
- `allOf` - Matches only if all provided schemas match
- `oneOf` - Matches exactly one of the provided schemas
- `not` - Inverts the matching logic of a schema

### Boolean Schemas
- `true` - Always matches (allows any value)
- `false` - Never matches (rejects all values)

## API Reference

### Creating Schemas

```swift
// String schema
JSONSchema.string(
    description: String? = nil,
    minLength: Int? = nil,
    maxLength: Int? = nil,
    pattern: String? = nil
)

// Object schema
JSONSchema.object(
    description: String? = nil,
    properties: [String: JSONSchema],
    required: [String]? = nil,
    additionalProperties: JSONSchema? = nil
)

// Array schema
JSONSchema.array(
    description: String? = nil,
    items: JSONSchema,
    minItems: Int? = nil,
    maxItems: Int? = nil,
    uniqueItems: Bool? = nil
)

// Number schemas
JSONSchema.integer(description: String? = nil, minimum: Int? = nil, maximum: Int? = nil)
JSONSchema.number(description: String? = nil, minimum: Double? = nil, maximum: Double? = nil)

// Other types
JSONSchema.boolean(description: String? = nil)
JSONSchema.null(description: String? = nil)
JSONSchema.enum(description: String? = nil, values: [String])

// Logical operators
JSONSchema.anyOf([JSONSchema])
JSONSchema.allOf([JSONSchema])
JSONSchema.oneOf([JSONSchema])
JSONSchema.not(JSONSchema)
```

## Requirements

- Swift 6.3+ (snapshot) for the `new-codable` branch
- Swift 6.1+ for the `main` branch

## License

Copyright (c) 2025 Tobias Haeberle

Licensed under the Apache License, Version 2.0
