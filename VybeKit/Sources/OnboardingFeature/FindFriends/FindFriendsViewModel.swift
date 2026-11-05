import Core
import Foundation
import Models

/// One person the app suggests, already as display text.
struct FriendSuggestionRow: Equatable, Sendable, Identifiable {
    let id: UserID
    let name: String
    /// "3 mutual friends"; nil when there are none.
    let reason: String?
    let photoURL: URL?
}

/// O5 (for new accounts, Phase 2): "People you may know" from `FriendsRepository` (mutual friends only; no phone
/// contacts, no college). Add sends a request; Skip, or Done once someone was added, finishes onboarding.
///
/// In Phase 1 onboarding ends at O4. When sign-in arrives, O4 opens this screen for new accounts instead of finishing.
@MainActor @Observable
final class FindFriendsViewModel {
    private(set) var state: LoadState<[FriendSuggestionRow]> = .loading
    /// People with a request sent (from this screen, or before).
    private(set) var requested: Set<UserID> = []
    /// Requests on their way, so a row cannot be tapped twice.
    private(set) var sending: Set<UserID> = []
    /// Why the last Add for a person failed, shown under their row.
    private(set) var addErrors: [UserID: String] = [:]
    /// "Done" once at least one request was sent from this screen, otherwise "Skip".
    private(set) var hasAddedSomeone = false
    private(set) var isFinished = false

    private let friends: any FriendsRepository
    private let photos: any PhotoStore
    private let session: SessionStore
    private let router: Router
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005).
    init(friends: any FriendsRepository, photos: any PhotoStore, session: SessionStore, router: Router) {
        self.friends = friends
        self.photos = photos
        self.session = session
        self.router = router
    }

    func load() async {
        guard !hasLoaded else { return }        // .task runs again whenever the screen reappears
        await fetch()
    }

    func reload() async { await fetch() }       // pull to refresh and the Retry button

    private func fetch() async {
        do {
            let people = try await friends.suggestions()
            if let sent = try? await friends.requests().sent {
                requested.formUnion(sent.map(\.toID))
            }
            var rows: [FriendSuggestionRow] = []
            for person in people {
                let mutual = (try? await friends.mutualFriends(with: person.id).count) ?? 0
                rows.append(FriendSuggestionRow(
                    id: person.id, name: person.displayName, reason: Self.mutualText(mutual),
                    photoURL: person.photo.flatMap(photos.url(for:))))
            }
            state = rows.isEmpty ? .empty : .loaded(rows)
            hasLoaded = true
        } catch is CancellationError {
            return                              // leaving the screen is not an error (ADR 005)
        } catch {
            if case .loaded(let rows, _) = state {
                state = .loaded(rows, isStale: true)   // a failed refresh keeps the list
            } else {
                state = .failed(AppError(error))       // only a first load can fail
            }
        }
    }

    // MARK: Actions

    func addTapped(_ id: UserID) async {
        guard !requested.contains(id), !sending.contains(id) else { return }
        sending.insert(id)
        addErrors[id] = nil
        defer { sending.remove(id) }
        do {
            _ = try await friends.sendRequest(to: id)
            requested.insert(id)
            hasAddedSomeone = true
        } catch is CancellationError {
            return
        } catch {
            addErrors[id] = AppError(error).message
        }
    }

    /// Skip or Done: saves the onboarding draft and switches the app to the tabs (as O4 does).
    func finishTapped() {
        guard !isFinished else { return }
        isFinished = true
        session.completeOnboarding()
        router.reset()
    }

    /// "1 mutual friend", "3 mutual friends"; nil for none.
    static func mutualText(_ count: Int) -> String? {
        count > 0 ? FindFriendsText.mutual(count) : nil
    }
}

/// O5's text, read from OnboardingFeature's own catalog (`bundle: #bundle`, task X-3).
enum FindFriendsText {
    static var title: String { String(localized: "onboarding.findFriends.title", bundle: #bundle) }
    static var subtitle: String { String(localized: "onboarding.findFriends.subtitle", bundle: #bundle) }
    static var empty: String { String(localized: "onboarding.findFriends.empty", bundle: #bundle) }
    static var skip: String { String(localized: "onboarding.findFriends.skip", bundle: #bundle) }
    static var done: String { String(localized: "onboarding.findFriends.done", bundle: #bundle) }

    /// "3 mutual friends", with the plural from the catalog.
    static func mutual(_ count: Int) -> String {
        String(localized: "onboarding.findFriends.mutual \(count)", bundle: #bundle)
    }
}
