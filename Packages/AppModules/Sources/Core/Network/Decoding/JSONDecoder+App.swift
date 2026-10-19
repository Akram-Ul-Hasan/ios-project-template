import Foundation

extension JSONDecoder {
    /// The one decoder configuration (§3a): snake_case keys, ISO-8601 dates with or without fractional seconds.
    /// Error bodies use a plain `JSONDecoder()` instead, so field-error keys keep the API's spelling.
    public static var app: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            if let date = try? Date(text, strategy: .iso8601) { return date }
            if let date = try? Date(text, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected an ISO-8601 date")
        }
        return decoder
    }
}

extension JSONEncoder {
    /// Request bodies: snake_case keys, ISO-8601 dates.
    public static var app: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .sortedKeys
        return encoder
    }
}
