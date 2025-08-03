# swift-json-schema

A type-safe Swift library for defining, reading, and modifying JSON Schema specifications.

## Overview

JSONSchema provides a native Swift representation of JSON Schema, allowing you to:
- Define schemas programmatically
- Read and parse existing JSON Schema files
- Modify and transform schemas
- Full `Codable` support for seamless JSON serialization

> **Note**: This library focuses on schema representation and manipulation. It does not currently provide validation functionality.

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/t089/swift-json-schema.git", from: "0.1.0")
]
```

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
// Enum schema with title
let statusSchema = JSONSchema.enum(
    title: "Order Status",
    description: "Current order status",
    values: ["pending", "processing", "shipped", "delivered"]
)

// Array schema with constraints
let tagsSchema = JSONSchema.array(
    title: "Tags",
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

### Advanced Schema Features

```swift
// String with format validation and examples
let emailSchema = JSONSchema.string(
    title: "Email Address",
    description: "User's email address",
    format: "email",
    examples: ["user@example.com", "admin@company.org"]
)

// Number with exclusive bounds and multiple constraints
let scoreSchema = JSONSchema.number(
    title: "Test Score",
    description: "Score as a percentage",
    default: 0.0,
    examples: [85.5, 92.3, 78.9],
    exclusiveMinimum: 0,
    exclusiveMaximum: 100,
    multipleOf: 0.1
)

// Integer with const value
let versionSchema = JSONSchema.integer(
    title: "API Version",
    description: "Supported API version",
    const: 1
)

// Boolean with default value
let enabledSchema = JSONSchema.boolean(
    title: "Feature Enabled",
    description: "Whether the feature is enabled",
    default: true,
    examples: [true, false]
)

// Complex object with all new features
let userSchema = JSONSchema.object(
    title: "User Profile",
    description: "Complete user profile information",
    properties: [
        "id": .integer(
            title: "User ID",
            description: "Unique user identifier",
            minimum: 1,
            examples: [123, 456, 789]
        ),
        "name": .string(
            title: "Full Name",
            description: "User's full name",
            default: "Anonymous",
            examples: ["John Doe", "Jane Smith"],
            minLength: 1,
            maxLength: 100
        ),
        "email": .string(
            title: "Email",
            description: "Contact email",
            format: "email",
            examples: ["user@example.com"]
        ),
        "age": .integer(
            title: "Age",
            description: "Age in years",
            minimum: 0,
            maximum: 150,
            multipleOf: 1
        ),
        "score": .number(
            title: "Performance Score",
            description: "User performance score",
            exclusiveMinimum: 0,
            maximum: 100,
            multipleOf: 0.01
        )
    ],
    required: ["id", "name", "email"]
)
```

### Reading and Writing JSON Schema

```swift
import FoundationEssentials

// Decode from JSON
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

// Encode to JSON
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let encoded = try encoder.encode(schema)
print(String(data: encoded, encoding: .utf8)!)
```


## Supported Schema Types

### Primitive Types
- `string` - Text values with optional length, pattern, and format constraints
- `number` - Floating-point numbers with optional range constraints and multiple validation
- `integer` - Integer values with optional range constraints and multiple validation
- `boolean` - True/false values with optional default and const values
- `null` - Null values

### Composite Types
- `object` - Objects with defined properties and validation rules
- `array` - Arrays with item type specifications and size constraints

### Special Types
- `enum` - String values restricted to a specific set

### Logical Operators
- `anyOf` - Matches if any of the provided schemas match
- `allOf` - Matches only if all provided schemas match
- `oneOf` - Matches exactly one of the provided schemas
- `not` - Inverts the matching logic of a schema

### Boolean Schemas
- `true` - Always matches (allows any value)
- `false` - Never matches (rejects all values)

## Additional Keywords Support

### Common Keywords (all schema types)
- `title` - Short, descriptive title for the schema
- `description` - Detailed description of the schema's purpose
- `default` - Default value when the property is not provided
- `examples` - Array of example values that are valid for this schema
- `const` - Restricts the value to exactly one specific value

### String-Specific Keywords
- `format` - Semantic format validation (email, date, uri, uuid, etc.)
- `minLength` / `maxLength` - String length constraints
- `pattern` - Regular expression pattern matching

### Numeric Keywords (integer and number)
- `minimum` / `maximum` - Inclusive bounds
- `exclusiveMinimum` / `exclusiveMaximum` - Exclusive bounds
- `multipleOf` - Value must be a multiple of this number

### Object Keywords
- `properties` - Schema definitions for object properties
- `required` - Array of required property names
- `additionalProperties` - Schema for properties not explicitly defined

### Array Keywords
- `items` - Schema for array items
- `minItems` / `maxItems` - Array size constraints
- `uniqueItems` - Whether all items must be unique

## API Reference

### Creating Schemas

```swift
// String schema
JSONSchema.string(
    title: String? = nil,
    description: String? = nil,
    default: String? = nil,
    examples: [String]? = nil,
    const: String? = nil,
    minLength: Int? = nil,
    maxLength: Int? = nil,
    pattern: String? = nil,
    format: String? = nil
)

// Object schema
JSONSchema.object(
    title: String? = nil,
    description: String? = nil,
    properties: [String: JSONSchema],
    required: [String]? = nil,
    additionalProperties: JSONSchema? = nil
)

// Array schema
JSONSchema.array(
    title: String? = nil,
    description: String? = nil,
    items: JSONSchema,
    minItems: Int? = nil,
    maxItems: Int? = nil,
    uniqueItems: Bool? = nil
)

// Integer schema
JSONSchema.integer(
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
)

// Number schema
JSONSchema.number(
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
)

// Boolean schema
JSONSchema.boolean(
    title: String? = nil,
    description: String? = nil,
    default: Bool? = nil,
    examples: [Bool]? = nil,
    const: Bool? = nil
)

// Null schema
JSONSchema.null(
    title: String? = nil,
    description: String? = nil
)

// Enum schema
JSONSchema.enum(
    title: String? = nil,
    description: String? = nil,
    values: [String]
)

// Logical operators
JSONSchema.anyOf([JSONSchema])
JSONSchema.allOf([JSONSchema])
JSONSchema.oneOf([JSONSchema])
JSONSchema.not(JSONSchema)
```

## Requirements

- Swift 6.1+

## License

Copyright (c) 2025 Tobias Haeberle

Licensed under the Apache License, Version 2.0
