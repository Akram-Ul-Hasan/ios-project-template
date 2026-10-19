/// Decodes a list, skipping (and logging) invalid items instead of failing the whole response.
/// Only where showing the valid items is genuinely acceptable, e.g. a recommendations carousel.
/// Never for cart, order lines or payment methods (§3a).
@propertyWrapper
public struct LossyArray<Element: Decodable>: Decodable {
    public var wrappedValue: [Element]

    public init(wrappedValue: [Element]) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements: [Element] = []
        var skipped = 0
        while !container.isAtEnd {
            if let element = try? container.decode(Element.self) {
                elements.append(element)
            } else {
                _ = try container.decode(Skip.self)  // a failed decode doesn't advance the container
                skipped += 1
            }
        }
        if skipped > 0 {
            let path = decoder.codingPath.map(\.stringValue).joined(separator: ".")
            AppLogger.network.error(
                "LossyArray skipped \(skipped, privacy: .public) invalid \(String(describing: Element.self), privacy: .public) at \(path, privacy: .public)"
            )
        }
        wrappedValue = elements
    }

    private struct Skip: Decodable {}
}

extension LossyArray: Equatable where Element: Equatable {}
extension LossyArray: Sendable where Element: Sendable {}
