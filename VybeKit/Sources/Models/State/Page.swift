import Foundation

/// One page of a list that loads more. `nextCursor == nil` means there is no next page.
public struct Page<Item> {
    public var items: [Item]
    public var nextCursor: String?

    public init(items: [Item], nextCursor: String? = nil) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

extension Page: Sendable where Item: Sendable {}
extension Page: Equatable where Item: Equatable {}
extension Page: Hashable where Item: Hashable {}
extension Page: Codable where Item: Codable {}
