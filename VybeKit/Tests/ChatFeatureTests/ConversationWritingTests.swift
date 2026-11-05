import Components
import Core
import Foundation
import Models
import Testing
@testable import ChatFeature

@MainActor
struct ConversationWritingTests {
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

    // MARK: Sending, editing, deleting

    @Test func sendingTextClearsTheBoxAndRecordsTheMessage() async {
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat)
        let viewModel = makeViewModel(chat: controlled)
        let task = await open(viewModel)
        viewModel.draft = "  See you at five  "
        #expect(viewModel.canSendDraft)
        await viewModel.sendTapped()
        #expect(viewModel.draft.isEmpty)
        #expect(controlled.sent.withLock { $0.last?.1 } == .text("See you at five"))
        task.cancel()
    }

    @Test func aFailedSendKeepsTheTextAndSaysWhy() async {
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat)
        controlled.failSend.withLock { $0 = true }
        let viewModel = makeViewModel(chat: controlled)
        let task = await open(viewModel)
        viewModel.draft = "Hello"
        await viewModel.sendTapped()
        #expect(viewModel.draft == "Hello" && viewModel.notice != nil)
        task.cancel()
    }

    @Test func youEditAndDeleteYourOwnTextButNotOthers() async {
        let myID = kit.myID, other = kit.ishaID
        let fixed = [message(1, from: other, at: 0), message(2, from: myID, at: 10)]
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat, messages: fixed)
        let viewModel = makeViewModel(chat: controlled)
        let task = await open(viewModel)
        #expect(!viewModel.canEdit("m-1") && !viewModel.canDelete("m-1"))
        #expect(viewModel.canEdit("m-2") && viewModel.canDelete("m-2"))
        task.cancel()
    }

    @Test func editingFillsTheBoxAndSavingChangesTheMessage() async {
        let viewModel = makeViewModel(direct)
        let task = await open(viewModel)
        guard let mine = rows(viewModel).last(where: \.isMine) else {
            Issue.record("no message of mine")
            task.cancel()
            return
        }
        viewModel.editTapped(mine.id)
        #expect(viewModel.editingID != nil && !viewModel.draft.isEmpty)
        viewModel.draft = "Edited words"
        await viewModel.sendTapped()
        #expect(viewModel.editingID == nil && viewModel.draft.isEmpty)
        for _ in 0..<100 where rows(viewModel).last(where: \.isMine)?.isEdited != true {
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(rows(viewModel).last(where: \.isMine)?.isEdited == true)
        task.cancel()
    }

    @Test func deletingAsksFirstThenShowsDeleted() async {
        let viewModel = makeViewModel(direct)
        let task = await open(viewModel)
        guard let mine = rows(viewModel).last(where: \.isMine) else {
            Issue.record("no message of mine")
            task.cancel()
            return
        }
        viewModel.deleteTapped(mine.id)
        viewModel.cancelDelete()
        await viewModel.confirmDelete()
        #expect(rows(viewModel).last(where: \.isMine)?.content != .deleted)
        viewModel.deleteTapped(mine.id)
        await viewModel.confirmDelete()
        for _ in 0..<100 where rows(viewModel).last(where: \.isMine)?.content != .deleted {
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(rows(viewModel).last(where: \.isMine)?.content == .deleted)
        task.cancel()
    }

    @Test func copyGivesTheTextAndReportIsForOthersMessagesOnly() async {
        let myID = kit.myID, other = kit.ishaID
        let fixed = [message(1, from: other, at: 0, .text("Hello there")), message(2, from: myID, at: 10)]
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(chat: ControlledChat(base: deps.chat, messages: fixed), deps: deps)
        let task = await open(viewModel)
        #expect(viewModel.copyText("m-1") == "Hello there")
        viewModel.reportTapped("m-2")
        #expect(deps.router.path(for: deps.router.currentStack).isEmpty)
        viewModel.reportTapped("m-1")
        #expect(deps.router.path(for: deps.router.currentStack).last == .report(.message("m-1")))
        task.cancel()
    }
}
