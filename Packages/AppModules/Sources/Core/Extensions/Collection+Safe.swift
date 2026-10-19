extension Collection {
    /// `nil` instead of a crash for an out-of-range index (rule 28): `items[safe: index]`.
    public subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
