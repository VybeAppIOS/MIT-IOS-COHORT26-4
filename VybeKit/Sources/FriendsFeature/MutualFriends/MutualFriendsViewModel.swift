import Core
import Foundation
import Models
import Observation

/// The view-ready values of the Mutual friends screen (never a raw model).
struct MutualFriendsContent: Equatable {
    let people: [PersonRowData]
}

/// Mutual friends (SC-PR7): the friends you and another person share. Tap one to see their profile.
@MainActor @Observable
final class MutualFriendsViewModel {
    private(set) var state: LoadState<MutualFriendsContent> = .loading
    private let userID: UserID
    private let friends: any FriendsRepository
    private let session: SessionStore
    private let router: Router
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(userID: UserID, friends: any FriendsRepository, session: SessionStore, router: Router) {
        self.userID = userID
        self.friends = friends
        self.session = session
        self.router = router
    }

    var title: String { String(localized: "friends.mutual.title", bundle: #bundle) }
    var emptyMessage: String { String(localized: "friends.mutual.empty", bundle: #bundle) }

    /// Called by `.task`. Runs once; `.task` runs again whenever the screen reappears.
    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    /// Pull to refresh and the Retry button.
    func reload() async { await fetch() }

    func personTapped(_ id: UserID) { router.open(.profile(id)) }

    private func fetch() async {
        do {
            let people = try await friends.mutualFriends(with: userID)
                .filter { !session.isBlocked($0.id) }
                .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
                .map { PersonRowData($0) }
            state = people.isEmpty ? .empty : .loaded(MutualFriendsContent(people: people))
            hasLoaded = true
        } catch is CancellationError {
            return   // leaving the screen is not an error (ADR 005)
        } catch {
            if case .loaded(let content, _) = state {
                state = .loaded(content, isStale: true)   // a failed refresh keeps what is on screen
            } else {
                state = .failed(AppError(error))   // only a first load can fail
            }
        }
    }
}
