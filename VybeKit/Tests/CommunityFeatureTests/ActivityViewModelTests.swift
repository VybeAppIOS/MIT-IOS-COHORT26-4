import Core
import Foundation
import Models
import Synchronization
import Testing
@testable import CommunityFeature

/// A feed whose Activity list is fixed by the test, and that remembers whether it was told "all read".
private final class ActivityFeed: FeedRepository {
    let items: [Activity]
    let markedRead = Mutex(false)
    let failActivity = Mutex(false)

    init(items: [Activity]) { self.items = items }

    func feed(after cursor: String?) async throws -> Page<HangoutRun> { Page(items: []) }
    func trending() async throws -> [HangoutRun] { [] }
    func post(id: RunID) async throws -> HangoutRun { throw AppError.notFound }
    func comments(for runID: RunID, after cursor: String?) async throws -> Page<Models.Comment> { Page(items: []) }
    func likes() async throws -> Set<LikeTarget> { [] }
    func like(_ target: LikeTarget) async throws {}
    func unlike(_ target: LikeTarget) async throws {}
    func addComment(to runID: RunID, text: String, replyingTo parentID: CommentID?) async throws -> Models.Comment {
        throw AppError.unknown
    }
    func deleteComment(_ id: CommentID) async throws {}
    func activity(after cursor: String?) async throws -> Page<Activity> {
        if failActivity.withLock({ $0 }) { throw AppError.offline }
        return Page(items: items)
    }
    func markActivityRead() async throws { markedRead.withLock { $0 = true } }
}

@MainActor
struct ActivityViewModelTests {
    private let now = SampleData.day
    private func hoursAgo(_ hours: Double) -> Date { now.addingTimeInterval(-hours * 3600) }

    private func sampleItems() -> [Activity] {
        let myID = SampleData.signedInUser.id
        return [
            Activity(id: "a-like", recipientID: myID, kind: .like, actorID: SampleSocialData.friend.id,
                     target: .run("run-sample-3"), createdAt: hoursAgo(1)),
            Activity(id: "a-request", recipientID: myID, kind: .friendRequest, actorID: SampleSocialData.sanya.id,
                     target: .user(SampleSocialData.sanya.id), createdAt: hoursAgo(5)),
            Activity(id: "a-comment", recipientID: myID, kind: .comment, actorID: SampleSocialData.rohan.id,
                     target: .comment("comment-sample-5"), createdAt: hoursAgo(3)),
            Activity(id: "a-accepted", recipientID: myID, kind: .friendAccepted, actorID: SampleSocialData.meera.id,
                     target: .user(SampleSocialData.meera.id), createdAt: hoursAgo(30), readAt: hoursAgo(29)),
            Activity(id: "a-remix", recipientID: myID, kind: .remixCredit, actorID: SampleSocialData.isha.id,
                     target: .hangout(SampleData.morning.id), createdAt: hoursAgo(50), readAt: hoursAgo(49)),
            Activity(id: "a-new-kind", recipientID: myID, kind: .unknown, actorID: SampleSocialData.isha.id,
                     target: .user(SampleSocialData.isha.id), createdAt: hoursAgo(2))
        ]
    }

    private struct Setup {
        let viewModel: ActivityViewModel
        let feed: ActivityFeed
        let deps: AppDependencies
        let badges: BadgeStore
    }

    private func makeSetup(items: [Activity]? = nil) -> Setup {
        let deps = AppDependencies.preview(.loaded)
        let feed = ActivityFeed(items: items ?? sampleItems())
        let badges = BadgeStore(chat: deps.chat, feed: feed, friends: deps.friends)
        let viewModel = ActivityViewModel(
            feed: feed, friends: deps.friends, profiles: deps.profiles, badges: badges, router: deps.router,
            now: { SampleData.day })
        return Setup(viewModel: viewModel, feed: feed, deps: deps, badges: badges)
    }

    private func rows(_ viewModel: ActivityViewModel) -> [ActivityRowData] {
        if case .loaded(let content, _) = viewModel.state { content.sections.flatMap(\.rows) } else { [] }
    }

    private func sections(_ viewModel: ActivityViewModel) -> [ActivitySection] {
        if case .loaded(let content, _) = viewModel.state { content.sections } else { [] }
    }

    @Test func rowsAreGroupedTodayThenEarlierAndUnknownKindsAreLeftOut() async {
        let setup = makeSetup()
        await setup.viewModel.load()
        let groups = sections(setup.viewModel)
        #expect(groups.map(\.id) == ["today", "earlier"])
        #expect(groups[0].rows.count == 3)
        #expect(groups[1].rows.count == 2)
        #expect(rows(setup.viewModel).count == 5)
    }

    @Test func aFriendRequestIsTheTopRowWithAcceptAndIgnore() async {
        let setup = makeSetup()
        await setup.viewModel.load()
        let first = rows(setup.viewModel)[0]
        #expect(first.id == "a-request" && first.phase == .waiting)
        #expect(rows(setup.viewModel).dropFirst().allSatisfy { $0.phase == .plain })
    }

    @Test func acceptingMakesYouFriendsAndClearsTheBadgeCount() async {
        let setup = makeSetup()
        await setup.badges.refresh()
        #expect(setup.badges.pendingRequestCount == 1)
        await setup.viewModel.load()
        await setup.viewModel.acceptTapped("a-request")
        #expect(rows(setup.viewModel)[0].phase == .accepted)
        #expect(setup.badges.pendingRequestCount == 0)
        let friends = try? await setup.deps.friends.friends()
        #expect(friends?.contains { $0.id == SampleSocialData.sanya.id } == true)
    }

    @Test func ignoringHidesTheRowAndNeverSaysDeclined() async throws {
        let setup = makeSetup()
        await setup.viewModel.load()
        setup.viewModel.ignoreTapped("a-request")
        #expect(!rows(setup.viewModel).contains { $0.id == "a-request" })
        #expect(!rows(setup.viewModel).contains { $0.text.localizedCaseInsensitiveContains("declin") })
        // The request itself is untouched: the other person is never told.
        #expect(try await setup.deps.friends.requests().received.count == 1)
    }

    @Test func openingTheScreenMarksEverythingReadAndClearsTheBadge() async {
        let setup = makeSetup()
        await setup.badges.refresh()
        #expect(setup.badges.unseenActivityCount == 4)   // the badge also counts the hidden unknown kind
        await setup.viewModel.load()
        #expect(setup.feed.markedRead.withLock { $0 })
        #expect(setup.badges.unseenActivityCount == 0)
    }

    @Test func newRowsHaveADotUntilTheNextLoad() async {
        let setup = makeSetup()
        await setup.viewModel.load()
        #expect(rows(setup.viewModel).filter(\.isUnread).count == 3)
    }

    @Test func tappingARowGoesThroughTheRouter() async {
        let setup = makeSetup()
        await setup.viewModel.load()
        let router = setup.deps.router
        setup.viewModel.rowTapped("a-like")
        #expect(router.path(for: router.currentStack).last == .post("run-sample-3"))
        setup.viewModel.rowTapped("a-accepted")
        #expect(router.path(for: router.currentStack).last == .profile(SampleSocialData.meera.id))
        setup.viewModel.rowTapped("a-remix")
        #expect(router.path(for: router.currentStack).last == .hangout(SampleData.morning.id))
        setup.viewModel.rowTapped("a-comment")
        #expect(router.path(for: router.currentStack).last == .profile(SampleSocialData.rohan.id))
    }

    @Test func aCommentOrReplyRowOpensItsPostAndOnlyFallsBackToTheProfileWithoutOne() async {
        let myID = SampleData.signedInUser.id
        let items = [
            Activity(id: "a-reply", recipientID: myID, kind: .reply, actorID: SampleSocialData.rohan.id,
                     target: .comment("comment-sample-5"), createdAt: hoursAgo(1), runID: "run-sample-3"),
            Activity(id: "a-comment", recipientID: myID, kind: .comment, actorID: SampleSocialData.isha.id,
                     target: .comment("comment-sample-6"), createdAt: hoursAgo(2), runID: "run-sample-5"),
            Activity(id: "a-old", recipientID: myID, kind: .comment, actorID: SampleSocialData.meera.id,
                     target: .comment("comment-sample-1"), createdAt: hoursAgo(3))
        ]
        let setup = makeSetup(items: items)
        await setup.viewModel.load()
        let router = setup.deps.router
        setup.viewModel.rowTapped("a-reply")
        #expect(router.path(for: router.currentStack).last == .post("run-sample-3"))
        setup.viewModel.rowTapped("a-comment")
        #expect(router.path(for: router.currentStack).last == .post("run-sample-5"))
        setup.viewModel.rowTapped("a-old")
        #expect(router.path(for: router.currentStack).last == .profile(SampleSocialData.meera.id))
    }

    @Test func theSampleCommentAndReplyRowsCarryTheirPost() {
        let rows = SampleSocialData.activity.filter { $0.kind == .comment || $0.kind == .reply }
        #expect(rows.count >= 2)
        #expect(rows.allSatisfy { $0.runID != nil })
        #expect(Set(rows.map(\.kind)) == [.comment, .reply])
    }

    @Test func noActivityIsTheEmptyState() async {
        let setup = makeSetup(items: [])
        await setup.viewModel.load()
        #expect(setup.viewModel.state == .empty)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = ActivityViewModel.preview(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }

    @Test func aFailedRefreshKeepsTheRowsAndMarksThemStale() async {
        let setup = makeSetup()
        await setup.viewModel.load()
        setup.feed.failActivity.withLock { $0 = true }
        await setup.viewModel.reload()
        guard case .loaded(let kept, let isStale) = setup.viewModel.state else {
            Issue.record("expected loaded, got \(setup.viewModel.state)")
            return
        }
        #expect(isStale && kept.sections.flatMap(\.rows).count == 5)
    }

    @Test func timesAreHowLongAgoNeverAClockTime() async {
        let setup = makeSetup()
        await setup.viewModel.load()
        #expect(rows(setup.viewModel).allSatisfy { !$0.relativeText.contains(":") })
    }
}
