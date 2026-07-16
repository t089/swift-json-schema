@preconcurrency import JSONMacros

@_exported import struct OrderedCollections.OrderedDictionary

/// NewCodable conformances for `OrderedDictionary` with string keys.
///
/// Unlike `Swift.Dictionary`, an `OrderedDictionary` preserves insertion
/// order, so encoding is deterministic and decode → encode round-trips
/// reproduce the original document's key order byte-for-byte. `JSONSchema`
/// uses it for `ObjectSchema.properties`, where consumers rely on
/// byte-stable output (e.g. LLM tool definitions that end up inside a
/// prompt-cache prefix).
extension OrderedDictionary: @retroactive JSONEncodable
where Key == String, Value: JSONEncodable {
    public func encode(to encoder: inout JSONDirectEncoder) throws(CodingError.Encoding) {
        try encoder.encodeStructFields(count: self.count) {
            structEncoder throws(CodingError.Encoding) in
            for (key, value) in self.elements {
                try structEncoder.encode(key: key, value: value)
            }
        }
    }
}

extension OrderedDictionary: @retroactive JSONDecodable
where Key == String, Value: JSONDecodable {
    public static func decode<D: JSONDecoderProtocol & ~Escapable>(
        from decoder: inout D
    ) throws(CodingError.Decoding) -> Self {
        try decoder.decodeStruct { structDecoder throws(CodingError.Decoding) in
            var result: OrderedDictionary<String, Value> = [:]
            try structDecoder.decodeEachKeyAndValue {
                key, valueDecoder throws(CodingError.Decoding) -> Bool in
                result[key] = try valueDecoder.decode(Value.self)
                return false
            }
            return result
        }
    }
}
