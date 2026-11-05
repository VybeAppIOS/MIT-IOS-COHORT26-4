import Components
import Core
import Foundation
import Models
import Testing
@testable import ChatFeature

@MainActor
struct ConversationLoadingTests {
    private let kit = ConversationKit()
    private var crew: ConversationID { kit.crew }
    private var direct: ConversationID { kit.direct }
    private func makeViewModel(
        _ id: ConversationID? = nil, chat: (any ChatRepository)? = nil, deps: AppDependencies = .preview(.loaded),
        recorder: FakeRecorder = FakeRecorder(), offline: Bool = false, session: SessionStore? = nil
    ) -> ConversationViewModel {
        kit.makeViewModel(id, chat: chat, deps: deps, recorder: recorder, offline: offline, session: session)
    }
    private func rows(_ viewModel: ConversationViewModel) -> [MessageRowData] { kit.rows(viewModel) }
    private func open(_ viewModel: ConversationViewModel) async -> Task<Void, Never> { await kit.open(viewModel) }
    private func message(
        _ number: Int, from sender: UserID, at seconds: TimeInterval, _ payload: MessagePayload = .text("hi")
    ) -> Message { kit.message(number, from: sender, at: seconds, payload) }

    // MARK: Loading and the stream

    @Test func theMessagesLoadNewestAtTheBottom() async {
        let viewModel = makeViewModel()
        let task = await open(viewModel)
        #expect(!rows(viewModel).isEmpty)
        task.cancel()
    }

    @Test func leavingTheScreenEndsTheStreamWithoutAnError() async {
        let viewModel = makeViewModel()
        let task = await open(viewModel)
        task.cancel()
        await task.value   // returns, which means the loop stopped
        if case .failed = viewModel.state { Issue.record("cancelling must not show an error") }
    }

    @Test func consecutiveMessagesFromOnePersonAreGrouped() async {
        let myID = kit.myID, other = kit.ishaID
        let fixed = [
            message(1, from: other, at: 0), message(2, from: other, at: 30), message(3, from: other, at: 700),
            message(4, from: myID, at: 710)
        ]
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat, messages: fixed)
        let viewModel = makeViewModel(chat: controlled)
        let task = await open(viewModel)
        #expect(rows(viewModel).map(\.startsGroup) == [true, false, true, true])
        #expect(rows(viewModel).map(\.isMine) == [false, false, false, true])
        task.cancel()
    }

    @Test func aBlockedPersonsMessagesAreHidden() async {
        let myID = kit.myID, other = kit.ishaID
        let fixed = [message(1, from: other, at: 0), message(2, from: myID, at: 10)]
        let deps = AppDependencies.preview(.loaded)
        let blocking = SessionStore(
            settings: AppSettings(suiteName: "test.\(UUID().uuidString)"), currentUser: SampleData.signedInUser,
            blockedIDs: [other])
        let viewModel = makeViewModel(
            chat: ControlledChat(base: deps.chat, messages: fixed), deps: deps, session: blocking)
        let task = await open(viewModel)
        #expect(rows(viewModel).count == 1 && rows(viewModel)[0].isMine)
        task.cancel()
    }

    @Test func aDeletedMessageShowsAsDeletedAndAnEditedOneIsTagged() async {
        let other = SampleSocialData.isha.id
        var deleted = message(1, from: other, at: 0)
        deleted.deletedAt = SampleData.day
        var edited = message(2, from: other, at: 10)
        edited.editedAt = SampleData.day
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat, messages: [deleted, edited])
        let viewModel = makeViewModel(chat: controlled)
        let task = await open(viewModel)
        #expect(rows(viewModel)[0].content == .deleted && rows(viewModel)[1].isEdited)
        task.cancel()
    }

    @Test func aMissingChatIsTheEmptyState() async {
        let viewModel = makeViewModel("conversation-gone")
        await viewModel.run()
        #expect(viewModel.state == .empty)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let deps = AppDependencies.preview(.failing)
        let viewModel = makeViewModel(deps: deps)
        await viewModel.run()
        #expect(viewModel.state == .failed(.offline))
    }

    // MARK: Read receipts

    @Test func aMessageIsSeenOnlyOnceSomeoneHasReadUpToIt() {
        let sent = message(1, from: SampleData.signedInUser.id, at: 100)
        #expect(ConversationViewModel.receipt(for: sent, othersLastReadAt: nil) == .delivered)
        #expect(ConversationViewModel.receipt(for: sent, othersLastReadAt: SampleData.day) == .delivered)
        let later = SampleData.day.addingTimeInterval(100)
        #expect(ConversationViewModel.receipt(for: sent, othersLastReadAt: later) == .seen)
    }

    @Test func onlyMyLastMessageShowsAReceipt() async {
        let myID = kit.myID
        let fixed = [message(1, from: myID, at: 0), message(2, from: myID, at: 10)]
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat, messages: fixed)
        let viewModel = makeViewModel(chat: controlled)
        let task = await open(viewModel)
        #expect(rows(viewModel).map(\.receipt) == [nil, .delivered])
        task.cancel()
    }
}
