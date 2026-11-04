import Foundation
import Models

/// Full-screen covers: long multi-step tasks, each with its own stack.
public enum Cover: Hashable, Codable, Sendable, Identifiable {
    /// H1, then H3 and PO1 pushed on the `.live` stack.
    case live(HangoutID)
    /// E1: new, from a draft, or a Remix.
    case editor(EditorStart)

    public var id: String {
        switch self {
        case .live(let id): "live-\(id.rawValue)"
        case .editor: "editor"
        }
    }
}
