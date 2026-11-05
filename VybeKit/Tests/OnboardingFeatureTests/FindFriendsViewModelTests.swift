import Core
import Foundation
import Models
import Testing
@testable import OnboardingFeature

/// A friends repository whose sending can fail, to check the row goes back to Add with an error.
private struct RefusingFriends: FriendsRepository {
    let base: any FriendsRepository
    func friends() async throws -> [UserProfile] { try await base.friends() }
    func requests() async throws -> FriendRequests { try await base.requests() }
    func suggestions() async throws -> [UserProfile] { try await base.suggestions() }
    func mutualFriends(with user: UserID) async throws -> [UserProfile] { try await base.mutualFriends(with: user) }
    func sendRequest(to user: UserID) async throws -> FriendRequest { throw AppError.offline }
    func acceptRequest(from user: UserID) async throws { try await base.acceptRequest(from: user) }
    func cancelRequest(to user: UserID) async throws { try await base.cancelRequest(to: user) }
    func removeFriend(_ user: UserID) async throws { try await base.removeFriend(user) }
}

@MainActor
struct FindFriendsViewModelTests {
    private func makeViewModel(
        _ deps: AppDependencies = .preview(), friends: (any FriendsRepository)? = nil, session: SessionStore? = nil
    ) -> FindFriendsViewModel {
        FindFriendsViewModel(friends: friends ?? deps.friends, photos: deps.photos, session: session ?? deps.session,
                             router: deps.router)
    }

    private func rows(_ viewModel: FindFriendsViewModel) -> [FriendSuggestionRow] {
        guard case .loaded(let rows, _) = viewModel.state else { return [] }
        return rows
    }

    // MARK: States (task SC-O5)

    @Test func loadedShowsThePeopleYouMayKnow() async throws {
        let deps = AppDependencies.preview()
        let viewModel = makeViewModel(deps)
        await viewModel.load()
        let expected = try await deps.friends.suggestions()
        #expect(rows(viewModel).map(\.id) == expected.map(\.id))
        #expect(!rows(viewModel).isEmpty)
    }

    @Test func noSuggestionsIsEmpty() async {
        let viewModel = makeViewModel(.preview(.empty))
        await viewModel.load()
        #expect(viewModel.state == .empty)
        #expect(FindFriendsText.empty == "No suggestions yet. Invite friends from a Hangout.")
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = makeViewModel(.preview(.failing))
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }

    // MARK: Add

    @Test func addSendsTheRequestAndTheRowShowsRequested() async throws {
        let deps = AppDependencies.preview()
        let viewModel = makeViewModel(deps)
        await viewModel.load()
        let person = try #require(rows(viewModel).first)
        await viewModel.addTapped(person.id)
        #expect(viewModel.requested.contains(person.id))
        #expect(viewModel.hasAddedSomeone)
        #expect(try await deps.friends.requests().sent.contains { $0.toID == person.id })
    }

    @Test func aFailedAddGoesBackToAddWithAnError() async throws {
        let deps = AppDependencies.preview()
        let viewModel = makeViewModel(deps, friends: RefusingFriends(base: deps.friends))
        await viewModel.load()
        let person = try #require(rows(viewModel).first)
        await viewModel.addTapped(person.id)
        #expect(!viewModel.requested.contains(person.id))
        #expect(viewModel.addErrors[person.id] != nil)
        #expect(!viewModel.hasAddedSomeone)
    }

    // MARK: Finishing

    @Test func skipFinishesOnboarding() async {
        let settings = AppSettings(suiteName: "vybe.test.\(UUID().uuidString)")
        let session = SessionStore(settings: settings, currentUser: SampleData.signedInUser)
        let deps = AppDependencies.preview()
        deps.router.setOnboarding(true)
        let viewModel = makeViewModel(deps, session: session)
        viewModel.finishTapped()
        #expect(session.onboardingDone)
        #expect(!deps.router.isOnboarding)
    }

    // MARK: Text

    @Test func theMutualFriendsTextUsesThePlural() {
        #expect(FindFriendsViewModel.mutualText(1) == "1 mutual friend")
        #expect(FindFriendsViewModel.mutualText(3) == "3 mutual friends")
        #expect(FindFriendsViewModel.mutualText(0) == nil)
    }
}
