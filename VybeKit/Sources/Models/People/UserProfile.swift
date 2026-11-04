import Foundation

/// Who may comment on my posts. Default: friends.
public enum CommentPolicy: String, Codable, Hashable, Sendable, CaseIterable {
    case everyone
    case friends
    case nobody
}

/// Who may send me a friend request. Default: everyone (requests from people with no mutual friends go to "Other").
public enum FriendRequestPolicy: String, Codable, Hashable, Sendable, CaseIterable {
    case everyone
    case friendsOfFriends
}

/// Who may add me to a group chat. Default: ask me (an add by a non-friend waits until I accept).
public enum GroupAddPolicy: String, Codable, Hashable, Sendable, CaseIterable {
    case friends
    case askMe
    case everyone
}

/// The privacy settings (screen ST2). Defaults are the safe ones from `docs/RISKS.md` 3.
public struct UserSettings: Codable, Hashable, Sendable {
    public var whoCanComment: CommentPolicy
    public var whoCanSendRequests: FriendRequestPolicy
    public var whoCanAddMeToGroups: GroupAddPolicy
    public var showMeInSearch: Bool
    /// The audience a new post starts with. Friends; Public is opt-in.
    public var defaultAudience: Visibility

    public init(
        whoCanComment: CommentPolicy = .friends, whoCanSendRequests: FriendRequestPolicy = .everyone,
        whoCanAddMeToGroups: GroupAddPolicy = .askMe, showMeInSearch: Bool = true,
        defaultAudience: Visibility = .friends
    ) {
        self.whoCanComment = whoCanComment
        self.whoCanSendRequests = whoCanSendRequests
        self.whoCanAddMeToGroups = whoCanAddMeToGroups
        self.showMeInSearch = showMeInSearch
        self.defaultAudience = defaultAudience
    }

    /// A setting missing from older saved data falls back to its safe default instead of failing the whole load.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        whoCanComment = try container.decodeIfPresent(CommentPolicy.self, forKey: .whoCanComment) ?? .friends
        whoCanSendRequests = try container.decodeIfPresent(FriendRequestPolicy.self, forKey: .whoCanSendRequests)
            ?? .everyone
        whoCanAddMeToGroups = try container.decodeIfPresent(GroupAddPolicy.self, forKey: .whoCanAddMeToGroups)
            ?? .askMe
        showMeInSearch = try container.decodeIfPresent(Bool.self, forKey: .showMeInSearch) ?? true
        defaultAudience = try container.decodeIfPresent(Visibility.self, forKey: .defaultAudience) ?? .friends
    }
}

/// A person's public profile plus their settings.
public struct UserProfile: Codable, Hashable, Sendable, Identifiable {
    public let id: UserID
    /// Unique and lower case.
    public var username: String
    public var displayName: String
    public var photo: Photo?
    public var banner: Photo?
    public var bio: String?
    public var isPrivate: Bool
    public var interests: [String]
    public var friendCount: Int
    public var settings: UserSettings
    public var createdAt: Date
    /// Set when the account is deleted; the person then shows as "[deleted]".
    public var deletedAt: Date?

    public init(
        id: UserID, username: String, displayName: String, photo: Photo? = nil, banner: Photo? = nil,
        bio: String? = nil, isPrivate: Bool = false, interests: [String] = [], friendCount: Int = 0,
        settings: UserSettings = UserSettings(), createdAt: Date, deletedAt: Date? = nil
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.photo = photo
        self.banner = banner
        self.bio = bio
        self.isPrivate = isPrivate
        self.interests = interests
        self.friendCount = friendCount
        self.settings = settings
        self.createdAt = createdAt
        self.deletedAt = deletedAt
    }
}

/// Data only the owner may read (a separate record on the server).
public struct AccountPrivate: Codable, Hashable, Sendable {
    public var dateOfBirth: Date
    public var confirmed18: Bool
    public var email: String?

    public init(dateOfBirth: Date, confirmed18: Bool, email: String? = nil) {
        self.dateOfBirth = dateOfBirth
        self.confirmed18 = confirmed18
        self.email = email
    }
}
