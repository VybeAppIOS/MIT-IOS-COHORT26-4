import Components
import Core
import Foundation
import Models
import Testing
@testable import FriendsFeature

@MainActor
struct OtherProfileViewModelTests {
    private func makeViewModel(
        _ user: UserProfile, friends: FakeFriends = .standard(), deps: AppDependencies = .preview(.loaded),
        session: SessionStore? = nil
    ) -> OtherProfileViewModel {
        OtherProfileViewModel(
            userID: user.id, profiles: deps.profiles, friends: friends, feed: deps.feed, places: deps.places,
            photos: deps.photos, session: session ?? deps.session, router: deps.router)
    }

    private func content(_ viewModel: OtherProfileViewModel) -> OtherProfileContent? {
        if case .loaded(let content, _) = viewModel.state { content } else { nil }
    }

    // MARK: The relationship

    @Test func theRelationshipFollowsTheLists() {
        let requests = FakeFriends.standard().state.withLock { state in
            FriendRequests(received: state.received, sent: state.sent, other: state.other)
        }
        let myFriends = [SampleSocialData.aarav]
        func relation(_ person: UserProfile) -> ProfileRelationship {
            OtherProfileViewModel.relationship(
                for: person, myID: SampleData.signedInUser.id, friends: myFriends, requests: requests)
        }
        #expect(relation(SampleData.signedInUser) == .own)
        #expect(relation(SampleSocialData.aarav) == .friends)
        #expect(relation(SampleSocialData.neel) == .requested)
        #expect(relation(SampleSocialData.sanya) == .respond)
        #expect(relation(SampleSocialData.tara) == .respond)   // an "Other" request can be answered too
        #expect(relation(SampleSocialData.kabir) == .privateGate)   // private and not a friend
        #expect(relation(SampleSocialData.meera) == .addFriend)
    }

    @Test func aFriendShowsTheirPostsAndAMessageButton() async {
        // The real stub knows `friend` as one of my friends, so use its own friends list.
        let deps = AppDependencies.preview(.loaded)
        let withFriend = OtherProfileViewModel(
            userID: SampleSocialData.friend.id, profiles: deps.profiles, friends: deps.friends, feed: deps.feed,
            places: deps.places, photos: deps.photos, session: deps.session, router: deps.router)
        await withFriend.load()
        let loaded = content(withFriend)
        #expect(loaded?.relationship == .friends && loaded?.canMessage == true)
        let expected = Set(SampleSocialData.posts.filter { $0.runnerID == SampleSocialData.friend.id }.map(\.id))
        #expect(Set(loaded?.tiles.map(\.id) ?? []) == expected)
        #expect(loaded?.header.hangoutsDone == expected.count)
    }

    // MARK: The private gate and blocked people

    @Test func aPrivateProfileShowsOnlyNameAndPhoto() async {
        let viewModel = makeViewModel(SampleSocialData.kabir)
        await viewModel.load()
        let loaded = content(viewModel)
        #expect(loaded?.relationship == .privateGate)
        #expect(loaded?.tiles.isEmpty == true)
        #expect(loaded?.header.bio == nil && loaded?.header.bannerURL == nil)
        #expect(loaded?.mutualFriendCount == 0 && loaded?.canMessage == false)
    }

    @Test func aBlockedPersonIsNotAvailableAndShowsNothing() async {
        let deps = AppDependencies.preview(.loaded)
        let blocking = SessionStore(
            settings: AppSettings(suiteName: "test.\(UUID().uuidString)"), currentUser: SampleData.signedInUser,
            blockedIDs: [SampleSocialData.aarav.id])
        let viewModel = makeViewModel(SampleSocialData.aarav, deps: deps, session: blocking)
        await viewModel.load()
        let loaded = content(viewModel)
        #expect(loaded?.relationship == .blocked)
        #expect(loaded?.tiles.isEmpty == true && loaded?.header.bio == nil && loaded?.header.avatarURL == nil)
        #expect(loaded?.canMessage == false)
    }

    // MARK: The big button

    @Test func addingAFriendBecomesRequested() async {
        let friends = FakeFriends.standard()
        let viewModel = makeViewModel(SampleSocialData.meera, friends: friends)
        await viewModel.load()
        await viewModel.headerButtonTapped()
        #expect(content(viewModel)?.relationship == .requested)
        #expect(friends.calls.withLock { $0 } == ["send \(SampleSocialData.meera.id.rawValue)"])
    }

    @Test func aFailedRequestGoesBackAndSaysWhy() async {
        let friends = FakeFriends.standard()
        let viewModel = makeViewModel(SampleSocialData.meera, friends: friends)
        await viewModel.load()
        friends.failChanges.withLock { $0 = true }
        await viewModel.headerButtonTapped()
        #expect(content(viewModel)?.relationship == .addFriend)
        #expect(viewModel.notice != nil)
    }

    @Test func tappingRequestedCancelsTheRequest() async {
        let friends = FakeFriends.standard()
        let viewModel = makeViewModel(SampleSocialData.neel, friends: friends)
        await viewModel.load()
        #expect(content(viewModel)?.relationship == .requested)
        await viewModel.headerButtonTapped()
        #expect(content(viewModel)?.relationship == .addFriend)
    }

    @Test func respondingMakesYouFriends() async {
        let friends = FakeFriends.standard()
        let viewModel = makeViewModel(SampleSocialData.sanya, friends: friends)
        await viewModel.load()
        #expect(content(viewModel)?.relationship == .respond)
        await viewModel.headerButtonTapped()
        #expect(content(viewModel)?.relationship == .friends)
        #expect(content(viewModel)?.canMessage == true)
    }

    @Test func tappingFriendsAsksBeforeRemoving() async {
        let friends = FakeFriends.standard()
        let viewModel = makeViewModel(SampleSocialData.aarav, friends: friends)
        await viewModel.load()
        await viewModel.headerButtonTapped()
        #expect(viewModel.isConfirmingRemove)
        #expect(content(viewModel)?.relationship == .friends)
        await viewModel.confirmRemove()
        #expect(content(viewModel)?.relationship == .addFriend)
    }

    // MARK: Routes

    @Test func tapsGoThroughTheRouter() async {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(SampleSocialData.aarav, deps: deps)
        let userID = SampleSocialData.aarav.id
        viewModel.mutualFriendsTapped()
        #expect(deps.router.path(for: deps.router.currentStack).last == .mutualFriends(userID))
        viewModel.postTapped("run-sample-4")
        #expect(deps.router.path(for: deps.router.currentStack).last == .post("run-sample-4"))
        viewModel.messageTapped()
        #expect(deps.router.path(for: deps.router.currentStack).last
            == .conversation(.dm(SampleData.signedInUser.id, userID)))
        viewModel.reportTapped()
        #expect(deps.router.sheet == .report(.user(userID)))
        viewModel.blockTapped()
        #expect(deps.router.sheet == .blockConfirm(userID))
    }

    // MARK: States

    @Test func aMissingPersonIsUnavailable() async {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = OtherProfileViewModel(
            userID: "user-nobody", profiles: deps.profiles, friends: FakeFriends.standard(), feed: deps.feed,
            places: deps.places, photos: deps.photos, session: deps.session, router: deps.router)
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = OtherProfileViewModel.preview(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }

    @Test func noPostIsShownWithAClockTime() async {
        let viewModel = makeViewModel(SampleSocialData.friend, friends: .standard())
        await viewModel.load()
        #expect(content(viewModel)?.tiles.allSatisfy { !$0.title.contains(":") } == true)
    }
}
