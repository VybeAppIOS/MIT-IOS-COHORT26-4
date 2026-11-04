import Foundation
import Models

/// CH1, CH2 and CH4 (CH3 and CH6 are local sheets, CH5 and CH7 are `Sheet`s).
public enum ChatRoute: Hashable, Codable, Sendable {
    case list
    case conversation(ConversationID)
    case groupInfo(ConversationID)
}

public extension Route {
    static let chatList = Route.chat(.list)
    static func conversation(_ id: ConversationID) -> Route { .chat(.conversation(id)) }
    static func groupInfo(_ id: ConversationID) -> Route { .chat(.groupInfo(id)) }
}
