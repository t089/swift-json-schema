# Add Support for Additional JSON Schema Keywords

## Overview

This PR significantly expands the swift-json-schema library by adding support for commonly used JSON Schema keywords that were previously missing. The changes enhance the library's functionality while maintaining backward compatibility and following the existing code patterns.

## ✨ New Features Added

### Common Keywords (All Schema Types)
- **`title`** - Short, descriptive title for schemas
- **`default`** - Default values when properties are not provided  
- **`examples`** - Array of example values that are valid for each schema
- **`const`** - Restricts values to exactly one specific value

### String-Specific Keywords
- **`format`** - Semantic format validation (email, date, uri, uuid, ipv4, ipv6, etc.)

### Numeric Keywords (Integer & Number)
- **`exclusiveMinimum`** - Exclusive lower bound (value must be greater than, not equal to)
- **`exclusiveMaximum`** - Exclusive upper bound (value must be less than, not equal to)  
- **`multipleOf`** - Value must be a multiple of this number

## 🔧 Changes Made

### Core Implementation
- Updated all schema structs to include new keyword properties
- Enhanced factory methods with additional parameters
- Maintained full `Codable` conformance for JSON serialization/deserialization
- Preserved existing API signatures for backward compatibility

### Files Modified
- **`Sources/JSONSchema/JSONSchema.swift`** - Main implementation with new keywords
- **`Tests/JSONSchemaTests/JSONSchemaTests.swift`** - Comprehensive test coverage
- **`README.md`** - Updated documentation with examples and API reference

### Schema Types Enhanced
- ✅ `StringSchema` - Added title, default, examples, const, format
- ✅ `ObjectSchema` - Added title  
- ✅ `ArraySchema` - Added title
- ✅ `IntegerSchema` - Added title, default, examples, const, exclusiveMinimum, exclusiveMaximum, multipleOf
- ✅ `NumberSchema` - Added title, default, examples, const, exclusiveMinimum, exclusiveMaximum, multipleOf
- ✅ `BooleanSchema` - Added title, default, examples, const
- ✅ `NullSchema` - Added title
- ✅ `EnumSchema` - Added title

## 📋 Examples

### Before (Limited Keywords)
```swift
let userSchema = JSONSchema.object(
    description: "User profile",
    properties: [
        "age": .integer(minimum: 0, maximum: 150)
    ]
)
```

### After (Rich Keywords Support)
```swift
let userSchema = JSONSchema.object(
    title: "User Profile",
    description: "Complete user profile information",
    properties: [
        "email": .string(
            title: "Email Address",
            format: "email",
            examples: ["user@example.com"]
        ),
        "age": .integer(
            title: "Age",
            description: "Age in years", 
            default: 18,
            examples: [25, 30, 45],
            exclusiveMinimum: 0,
            maximum: 150,
            multipleOf: 1
        ),
        "score": .number(
            title: "Performance Score",
            exclusiveMinimum: 0.0,
            exclusiveMaximum: 100.0,
            multipleOf: 0.1
        )
    ]
)
```

## 🧪 Testing

Added comprehensive test coverage including:
- **Encoding Tests** - Verify new keywords serialize correctly to JSON
- **Decoding Tests** - Ensure new keywords parse correctly from JSON Schema
- **Keyword-Specific Tests** - Individual tests for const, format, exclusive bounds, multipleOf
- **Round-trip Tests** - Encode/decode cycles preserve all data

### Test Cases Added
- `testNewKeywordsEncoding()` - Validates JSON output contains new keywords
- `testNewKeywordsDecoding()` - Verifies parsing of extended JSON Schema
- `testConstKeyword()` - Tests const value constraints
- `testFormatKeyword()` - Validates format string support  
- `testExclusiveBounds()` - Tests exclusive min/max constraints
- `testMultipleOfKeyword()` - Verifies multipleOf validation setup

## 📚 Documentation Updates

### README Enhancements
- Added "Advanced Schema Features" section with comprehensive examples
- Updated API Reference with all new parameters
- Added "Additional Keywords Support" section explaining each keyword
- Enhanced existing examples to showcase new capabilities

### Code Documentation
- Updated all method and property documentation
- Added parameter descriptions for new keywords
- Maintained consistent documentation style

## 🔄 Backward Compatibility

✅ **Fully backward compatible** - All existing code will continue to work unchanged

- All new parameters are optional with `nil` defaults
- Existing factory method signatures remain valid
- No breaking changes to public API
- Existing tests continue to pass

## 🎯 Use Cases Enabled

This enhancement enables many new use cases:

1. **API Documentation** - Rich schemas with titles, examples, and format validation
2. **Configuration Management** - Default values and const constraints  
3. **Data Validation Prep** - Exclusive bounds and multipleOf constraints
4. **UI Generation** - Examples and format hints for form generation
5. **OpenAPI Integration** - Full support for OpenAPI schema specifications

## 🏗️ Technical Notes

- Uses Swift's `Codable` for automatic JSON Schema serialization
- Leverages optional parameters for clean API design
- Maintains type safety throughout the implementation
- Follows existing code patterns and conventions
- No external dependencies added

## 📊 Impact

- **Lines of Code**: ~400 lines added (implementation + tests + docs)
- **Test Coverage**: 6 new test methods covering all new keywords
- **API Surface**: Expanded but backward-compatible
- **Documentation**: Significantly enhanced with examples

This PR brings swift-json-schema much closer to full JSON Schema Draft-07 specification compliance while maintaining the library's focus on schema representation and manipulation rather than validation.