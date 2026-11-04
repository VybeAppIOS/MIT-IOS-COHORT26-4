import Foundation

/// A photo attached to a Place or a post. A value, not its own record (`docs/DATA-MODEL.md` 3).
public struct Photo: Codable, Hashable, Sendable, Identifiable {
    public let id: PhotoID
    /// A bundle file in Phase 1, a storage path in Phase 2.
    public var path: String
    public var width: Int
    public var height: Int
    public var credit: String?
    public var spotID: SpotID?

    public init(id: PhotoID, path: String, width: Int, height: Int, credit: String? = nil, spotID: SpotID? = nil) {
        self.id = id
        self.path = path
        self.width = width
        self.height = height
        self.credit = credit
        self.spotID = spotID
    }
}
