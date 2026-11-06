import Core
import Foundation
import Models

/// One choice in a menu, ready to draw.
struct PrivacyChoice<Value: Hashable & Sendable>: Identifiable, Equatable {
    let value: Value
    let title: String

    var id: Value { value }
}

/// What the Privacy page shows: the current profile and its settings.
struct PrivacyContent: Equatable {
    var profile: UserProfile
}

/// ST2, Privacy. Six options, each saved the moment it changes through `ProfileRepository.update`. The defaults are
/// the safe ones from `docs/RISKS.md` 3 and are never weakened here: a private profile forces new posts to
/// friends-only, and Everyone is a clearly warned choice.
@MainActor @Observable
final class PrivacyViewModel {
    private(set) var state: LoadState<PrivacyContent> = .loading
    private(set) var saveFailed = false
    private(set) var isSaving = false

    private let profiles: any ProfileRepository
    private let session: SessionStore
    private let network: NetworkMonitor
    private var hasLoaded = false

    /// Cheap: nothing loads here (ADR 005).
    init(profiles: any ProfileRepository, session: SessionStore, network: NetworkMonitor) {
        self.profiles = profiles
        self.session = session
        self.network = network
    }

    // MARK: Words

    var title: String { String(localized: "profile.privacy.title", bundle: #bundle) }
    var privateTitle: String { String(localized: "profile.privacy.private", bundle: #bundle) }
    var privateHint: String { String(localized: "profile.privacy.private.hint", bundle: #bundle) }
    var audienceTitle: String { String(localized: "profile.privacy.audience", bundle: #bundle) }
    var commentTitle: String { String(localized: "profile.privacy.comment", bundle: #bundle) }
    var requestsTitle: String { String(localized: "profile.privacy.requests", bundle: #bundle) }
    var groupsTitle: String { String(localized: "profile.privacy.groups", bundle: #bundle) }
    var searchTitle: String { String(localized: "profile.privacy.search", bundle: #bundle) }
    var searchHint: String { String(localized: "profile.privacy.search.hint", bundle: #bundle) }
    var publicWarning: String { String(localized: "profile.privacy.audience.warning", bundle: #bundle) }
    var privateAudienceNote: String { String(localized: "profile.privacy.audience.private", bundle: #bundle) }
    var errorText: String { String(localized: "profile.privacy.error", bundle: #bundle) }
    var offlineText: String { String(localized: "profile.privacy.offline", bundle: #bundle) }

    // MARK: What the screen shows

    var profile: UserProfile? {
        if case .loaded(let content, _) = state { return content.profile }
        return nil
    }

    var isOffline: Bool { network.isOffline }
    /// Controls are off while offline or while a save is running.
    var canChange: Bool { !isOffline && !isSaving }
    var isPrivate: Bool { profile?.isPrivate ?? false }
    var showsPublicWarning: Bool { !isPrivate && profile?.settings.defaultAudience == .public }
    /// A private profile keeps new posts friends-only, so the audience menu is off.
    var canChangeAudience: Bool { canChange && !isPrivate }

    var audienceChoices: [PrivacyChoice<Visibility>] {
        [PrivacyChoice(value: .friends, title: String(localized: "profile.privacy.audience.friends", bundle: #bundle)),
         PrivacyChoice(value: .public, title: String(localized: "profile.privacy.audience.public", bundle: #bundle))]
    }

    var commentChoices: [PrivacyChoice<CommentPolicy>] {
        [PrivacyChoice(value: .everyone, title: String(localized: "profile.privacy.comment.everyone", bundle: #bundle)),
         PrivacyChoice(value: .friends, title: String(localized: "profile.privacy.comment.friends", bundle: #bundle)),
         PrivacyChoice(value: .nobody, title: String(localized: "profile.privacy.comment.nobody", bundle: #bundle))]
    }

    var requestChoices: [PrivacyChoice<FriendRequestPolicy>] {
        [PrivacyChoice(value: .everyone,
                       title: String(localized: "profile.privacy.requests.everyone", bundle: #bundle)),
         PrivacyChoice(value: .friendsOfFriends,
                       title: String(localized: "profile.privacy.requests.fof", bundle: #bundle))]
    }

    var groupChoices: [PrivacyChoice<GroupAddPolicy>] {
        [PrivacyChoice(value: .friends, title: String(localized: "profile.privacy.groups.friends", bundle: #bundle)),
         PrivacyChoice(value: .askMe, title: String(localized: "profile.privacy.groups.askMe", bundle: #bundle)),
         PrivacyChoice(value: .everyone, title: String(localized: "profile.privacy.groups.everyone", bundle: #bundle))]
    }

    // MARK: Loading

    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    func reload() async { await fetch() }

    private func fetch() async {
        do {
            let mine = try await profiles.currentProfile()
            state = .loaded(PrivacyContent(profile: mine))
            hasLoaded = true
        } catch is CancellationError {
            return   // leaving the screen is not an error (ADR 005)
        } catch {
            if case .loaded = state { return }
            state = .failed(AppError(error))
        }
    }

    // MARK: What the person does

    func setPrivate(_ enabled: Bool) async {
        await change {
            $0.isPrivate = enabled
            if enabled { $0.settings.defaultAudience = .friends }   // a private profile never posts publicly
        }
    }

    /// Ignored while the profile is private: new posts stay friends-only, whatever the screen allows.
    func setAudience(_ value: Visibility) async {
        guard !isPrivate else { return }
        await change { $0.settings.defaultAudience = value }
    }
    func setComment(_ value: CommentPolicy) async { await change { $0.settings.whoCanComment = value } }
    func setRequests(_ value: FriendRequestPolicy) async { await change { $0.settings.whoCanSendRequests = value } }
    func setGroups(_ value: GroupAddPolicy) async { await change { $0.settings.whoCanAddMeToGroups = value } }
    func setShowInSearch(_ enabled: Bool) async { await change { $0.settings.showMeInSearch = enabled } }

    /// Applies one change on screen at once and saves it. If saving fails, the old value comes back and a note says so.
    private func change(_ edit: (inout UserProfile) -> Void) async {
        guard canChange, var updated = profile else { return }
        let before = updated
        edit(&updated)
        guard updated != before else { return }
        state = .loaded(PrivacyContent(profile: updated))
        isSaving = true
        defer { isSaving = false }
        do {
            let saved = try await profiles.update(updated)
            state = .loaded(PrivacyContent(profile: saved))
            session.setCurrentUser(saved)
            saveFailed = false
        } catch is CancellationError {
            state = .loaded(PrivacyContent(profile: before))
        } catch {
            state = .loaded(PrivacyContent(profile: before))
            saveFailed = true
        }
    }
}
