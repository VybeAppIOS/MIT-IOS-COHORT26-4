import Components
import Core
import Foundation
import Models
import Testing
@testable import ChatFeature

/// "Seen" under my last message: the read times of the other members, reloaded whenever the messages change.
@MainActor
struct ConversationReceiptsTests {
    private let kit = ConversationKit()
    private var aaravChat: ConversationID { SampleSocialData.aaravChat.id }
    private var aarav: UserID { SampleSocialData.aarav.id }

    private func makeViewModel(
        _ id: ConversationID? = nil, chat: (any ChatRepository)? = nil, session: SessionStore? = nil
    ) -> ConversationViewModel {
        kit.makeViewModel(id, chat: chat, session: session)
    }
    private func rows(_ viewModel: ConversationViewModel) -> [MessageRowData] { kit.rows(viewModel) }
    private func lastReceipt(_ viewModel: ConversationViewModel) -> MessageRowData.Receipt? {
        rows(viewModel).last?.receipt
    }

    private func membership(_ user: UserID, readAt: TimeInterval?, status: MembershipStatus = .active) -> Membership {
        Membership(
            conversationID: kit.crew, userID: user, status: status, joinedAt: SampleData.day,
            lastReadAt: readAt.map { SampleData.day.addingTimeInterval($0) })
    }

    /// Opens the crew chat with one message of mine at time 0 and these members.
    private func openWithMembers(
        _ members: [Membership], session: SessionStore? = nil
    ) async -> (ConversationViewModel, Task<Void, Never>) {
        let fixed = [kit.message(1, from: kit.myID, at: 0)]
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat, messages: fixed)
        controlled.membershipsOverride.withLock { $0 = members }
        let viewModel = makeViewModel(chat: controlled, session: session)
        return (viewModel, await kit.open(viewModel))
    }

    @Test func theSampleDirectMessageShowsSeenBecauseTheOtherPersonReadIt() async {
        let viewModel = makeViewModel(aaravChat)
        let task = await kit.open(viewModel)
        #expect(rows(viewModel).last?.isMine == true)
        #expect(lastReceipt(viewModel) == .seen)
        task.cancel()
    }

    @Test func noReadTimeMeansDelivered() async {
        let members = [membership(kit.myID, readAt: 50), membership(kit.ishaID, readAt: nil)]
        let (viewModel, task) = await openWithMembers(members)
        #expect(lastReceipt(viewModel) == .delivered)
        task.cancel()
    }

    @Test func readingBeforeMyMessageIsNotSeenAndReadingAfterIsSeen() async {
        let (before, beforeTask) = await openWithMembers([membership(kit.ishaID, readAt: -5)])
        #expect(lastReceipt(before) == .delivered)
        beforeTask.cancel()
        let (after, afterTask) = await openWithMembers([membership(kit.ishaID, readAt: 5)])
        #expect(lastReceipt(after) == .seen)
        afterTask.cancel()
    }

    @Test func myOwnReadTimeNeverMakesItSeen() async {
        let members = [membership(kit.myID, readAt: 500), membership(kit.ishaID, readAt: nil)]
        let (viewModel, task) = await openWithMembers(members)
        #expect(lastReceipt(viewModel) == .delivered)
        task.cancel()
    }

    @Test func inAGroupTheNewestReadOfAnyoneCounts() async {
        let members = [membership(kit.ishaID, readAt: -5), membership(SampleSocialData.aarav.id, readAt: 20)]
        let (viewModel, task) = await openWithMembers(members)
        #expect(lastReceipt(viewModel) == .seen)
        task.cancel()
    }

    @Test func aBlockedPersonsReadDoesNotCountAndNeitherDoesAPendingMember() async {
        let blocking = SessionStore(
            settings: AppSettings(suiteName: "test.\(UUID().uuidString)"), currentUser: SampleData.signedInUser,
            blockedIDs: [kit.ishaID])
        let (blocked, blockedTask) = await openWithMembers([membership(kit.ishaID, readAt: 50)], session: blocking)
        #expect(lastReceipt(blocked) == .delivered)
        blockedTask.cancel()
        let (pending, pendingTask) = await openWithMembers([membership(kit.ishaID, readAt: 50, status: .pending)])
        #expect(lastReceipt(pending) == .delivered)
        pendingTask.cancel()
    }

    @Test func theReadTimesAreReloadedWhenTheMessagesChange() async {
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat)
        let viewModel = makeViewModel(aaravChat, chat: controlled)
        let task = await kit.open(viewModel)
        let callsAtStart = controlled.membershipCalls.withLock { $0 }
        #expect(lastReceipt(viewModel) == .seen)

        // A new message of mine is newer than the sample read time, so it is only delivered.
        let before = rows(viewModel).count
        _ = try? await controlled.send(.text("one"), in: aaravChat)
        for _ in 0..<200 where rows(viewModel).count == before { try? await Task.sleep(for: .milliseconds(10)) }
        #expect(rows(viewModel).count == before + 1)
        #expect(lastReceipt(viewModel) == .delivered)
        #expect(controlled.membershipCalls.withLock { $0 } > callsAtStart)

        // The other person reads it: the next change of the messages picks the new time up.
        controlled.membershipsOverride.withLock {
            $0 = [membership(aarav, readAt: 100_000)]
        }
        _ = try? await controlled.send(.text("two"), in: aaravChat)
        for _ in 0..<200 where rows(viewModel).count == before + 1 { try? await Task.sleep(for: .milliseconds(10)) }
        #expect(lastReceipt(viewModel) == .seen)
        task.cancel()
    }

    @Test func theStubReportsOtherPeoplesReadTimesOnTheirMembership() async throws {
        let members = try await AppDependencies.preview(.loaded).chat.memberships(in: kit.crew)
        let others = members.filter { $0.userID != kit.myID }
        #expect(!others.isEmpty && others.allSatisfy { $0.lastReadAt != nil })
    }
}
