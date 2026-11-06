import Design
import SwiftUI

/// Everything the top of a profile shows, already as display text.
public struct ProfileHeaderData: Hashable, Sendable {
    public var name: String
    /// "@sample.isha"
    public var username: String
    public var bio: String?
    public var bannerURL: URL?
    public var avatarURL: URL?
    public var isVerifiedVybe: Bool
    public var hangoutsDone: Int
    public var spotsVisited: Int
    /// Only on your own profile (friend lists are private).
    public var friendCount: Int?
    /// "3 mutual friends", built by the ViewModel (plural rules in its catalog).
    public var mutualFriendsText: String?

    public init(
        name: String, username: String, bio: String? = nil, bannerURL: URL? = nil, avatarURL: URL? = nil,
        isVerifiedVybe: Bool = false, hangoutsDone: Int = 0, spotsVisited: Int = 0, friendCount: Int? = nil,
        mutualFriendsText: String? = nil
    ) {
        self.name = name
        self.username = username
        self.bio = bio
        self.bannerURL = bannerURL
        self.avatarURL = avatarURL
        self.isVerifiedVybe = isVerifiedVybe
        self.hangoutsDone = hangoutsDone
        self.spotsVisited = spotsVisited
        self.friendCount = friendCount
        self.mutualFriendsText = mutualFriendsText
    }
}

/// The relationship button under a profile, one state at a time.
public enum ProfileRelationship: Hashable, Sendable, CaseIterable {
    /// My own profile: "Edit profile".
    case own
    case addFriend
    /// I sent a request: tapping cancels it.
    case requested
    /// They sent me a request: tapping shows Accept / Ignore.
    case respond
    case friends
    /// I blocked them: tapping offers Unblock.
    case blocked
    /// A private account I am not friends with: "Add friend" plus the private notice instead of their posts.
    case privateGate
}

/// The top of PR1 (my profile) and PR3 (someone else's): banner, photo, name, @username, bio, stats and the
/// relationship button. The button's look always matches its words, so state is never colour alone.
public struct ProfileHeader: View {
    private let data: ProfileHeaderData
    /// Half the 96 pt photo plus a little air; scales with Dynamic Type like the photo itself.
    @ScaledMetric(relativeTo: .body) private var avatarRoom = Theme.Spacing.huge + Theme.Spacing.large
    private let relationship: ProfileRelationship
    private let action: () -> Void

    public init(_ data: ProfileHeaderData, relationship: ProfileRelationship, action: @escaping () -> Void) {
        self.data = data
        self.relationship = relationship
        self.action = action
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            banner
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                names
                if let bio = data.bio {
                    Text(verbatim: bio).font(Theme.Font.body).foregroundStyle(Theme.Color.textPrimary)
                }
                if let mutual = data.mutualFriendsText {
                    Text(verbatim: mutual).font(Theme.Font.footnote).foregroundStyle(Theme.Color.textSecondary)
                }
                ProfileStats(data: data)
                RelationshipButton(relationship: relationship, action: action)
                if relationship == .privateGate { PrivateNotice() }
            }
            .padding(.horizontal, Theme.Spacing.large)
        }
    }

    @ViewBuilder private var bannerPicture: some View {
        if data.bannerURL != nil {
            PlaceImage(url: data.bannerURL, aspectRatio: 3)
        } else {
            // No banner yet: a soft brand gradient, never a broken-picture box.
            LinearGradient(colors: [Theme.Color.accent, Theme.Color.mint], startPoint: .leading, endPoint: .trailing)
                .aspectRatio(3, contentMode: .fit)
                .accessibilityHidden(true)
        }
    }

    private var banner: some View {
        bannerPicture
            .overlay(alignment: .bottomLeading) {
                Avatar(url: data.avatarURL, name: data.name, size: .extraLarge, isVerifiedVybe: data.isVerifiedVybe)
                    .overlay(Circle().stroke(Theme.Color.surface, lineWidth: 3))
                    .padding(.leading, Theme.Spacing.large)
                    .alignmentGuide(.bottom) { $0[.bottom] - $0.height / 2 }
            }
            // Room for the half of the photo that hangs below the banner. It grows with the photo (which follows
            // Dynamic Type), so the name never slides under the photo at large text sizes.
            .padding(.bottom, avatarRoom)
    }

    private var names: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: data.name)
                .font(Theme.Font.title2.weight(.bold))
                .foregroundStyle(Theme.Color.textPrimary)
            Text(verbatim: data.username)
                .font(Theme.Font.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Hangouts done, Spots visited and (own profile only) friends.
private struct ProfileStats: View {
    let data: ProfileHeaderData

    var body: some View {
        HStack(spacing: Theme.Spacing.extraLarge) {
            stat(data.hangoutsDone, ComponentStrings.hangoutsDone)
            stat(data.spotsVisited, ComponentStrings.spotsVisited)
            if let friends = data.friendCount { stat(friends, ComponentStrings.friendCount) }
        }
    }

    private func stat(_ value: Int, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value, format: .number).font(Theme.Font.headline).foregroundStyle(Theme.Color.textPrimary)
            Text(verbatim: label).font(Theme.Font.caption).foregroundStyle(Theme.Color.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct RelationshipButton: View {
    let relationship: ProfileRelationship
    let action: () -> Void

    var body: some View {
        switch relationship {
        case .own: SecondaryButton(verbatim: ComponentStrings.editProfile, action: action)
        case .addFriend, .privateGate: PrimaryButton(verbatim: ComponentStrings.addFriend, action: action)
        case .requested: SecondaryButton(verbatim: ComponentStrings.requested, action: action)
        case .respond: PrimaryButton(verbatim: ComponentStrings.respond, action: action)
        case .friends: SecondaryButton(verbatim: ComponentStrings.friends, action: action)
        case .blocked: SecondaryButton(verbatim: ComponentStrings.blocked, action: action)
        }
    }
}

private struct PrivateNotice: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            Image(systemName: "lock.fill")
                .font(Theme.Font.title2)
                .foregroundStyle(Theme.Color.textSecondary)
                .accessibilityHidden(true)
            Text(verbatim: ComponentStrings.privateAccount).font(Theme.Font.headline)
            Text(verbatim: ComponentStrings.privateHint)
                .font(Theme.Font.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.large)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#if DEBUG
private let own = ProfileHeaderData(
    name: "Sample Me", username: "@sample.me", bio: "EXAMPLE bio, Kothrud", hangoutsDone: 12, spotsVisited: 41,
    friendCount: 5)
private let other = ProfileHeaderData(
    name: "Sample Isha", username: "@sample.isha",
    bio: "EXAMPLE A long bio that wraps onto several lines: chai, treks around Pune, board games on Sundays and "
        + "always up for a new café in Kothrud.",
    hangoutsDone: 7, spotsVisited: 23, mutualFriendsText: "3 mutual friends")

#Preview("Own profile") {
    ScrollView { ProfileHeader(own, relationship: .own) {} }
}

#Preview("Every relationship") {
    ScrollView {
        VStack(spacing: Theme.Spacing.huge) {
            ForEach(ProfileRelationship.allCases, id: \.self) { relationship in
                ProfileHeader(other, relationship: relationship) {}
            }
        }
    }
}

#Preview("Vybe account, large text") {
    ScrollView {
        ProfileHeader(ProfileHeaderData(name: "Vybe", username: "@vybe", isVerifiedVybe: true, hangoutsDone: 40),
                      relationship: .addFriend) {}
    }
    .dynamicTypeSize(.accessibility3)
}
#endif
