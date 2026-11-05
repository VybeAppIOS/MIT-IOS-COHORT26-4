import Design
import Core
import Foundation
import Models
import Testing
@testable import ChatFeature

@MainActor
struct PollViewModelTests {
    private final class Closed { var count = 0 }

    private func makeViewModel(
        chat: (any ChatRepository)? = nil, offline: Bool = false, closed: Closed = Closed()
    ) -> PollViewModel {
        let deps = AppDependencies.preview(.loaded)
        return PollViewModel(
            conversationID: SampleSocialData.crew.id, chat: chat ?? deps.chat,
            network: NetworkMonitor(isOffline: offline), onClose: { closed.count += 1 })
    }

    @Test func anEmptyQuestionCannotBeSent() {
        let viewModel = makeViewModel()
        #expect(!viewModel.canSend)
        viewModel.question = "   \n"
        #expect(!viewModel.canSend)
        viewModel.question = "Coffee at 5?"
        #expect(viewModel.canSend)
    }

    @Test func theAnswersAreExactlyImInAndNotForMe() {
        let viewModel = makeViewModel()
        #expect(viewModel.options == [ComponentStrings.pollImIn, ComponentStrings.pollNotForMe])
        #expect(viewModel.options == ["I'm in", "Not for me"])
    }

    @Test func aTooLongQuestionCannotBeSent() {
        let viewModel = makeViewModel()
        viewModel.question = String(repeating: "a", count: PollViewModel.questionLimit)
        #expect(viewModel.canSend)
        viewModel.question += "a"
        #expect(!viewModel.canSend)
    }

    @Test func sendPostsAPollMessageAndClosesTheSheet() async {
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat)
        let closed = Closed()
        let viewModel = makeViewModel(chat: controlled, closed: closed)
        viewModel.question = "  Coffee at 5?  "
        await viewModel.sendTapped()
        let sent = controlled.sent.withLock { $0 }
        #expect(sent.count == 1 && sent.first?.1 == .poll(question: "Coffee at 5?"))
        #expect(sent.first?.0 == SampleSocialData.crew.id)
        #expect(closed.count == 1)
    }

    @Test func aFailedSendKeepsTheQuestionAndStaysOpen() async {
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat)
        controlled.failSend.withLock { $0 = true }
        let closed = Closed()
        let viewModel = makeViewModel(chat: controlled, closed: closed)
        viewModel.question = "Coffee at 5?"
        await viewModel.sendTapped()
        #expect(viewModel.question == "Coffee at 5?" && viewModel.notice != nil && closed.count == 0)
    }

    @Test func offlineCannotSend() {
        let viewModel = makeViewModel(offline: true)
        viewModel.question = "Coffee at 5?"
        #expect(!viewModel.canSend)
    }

    @Test func cancelClosesWithoutSending() async {
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat)
        let closed = Closed()
        let viewModel = makeViewModel(chat: controlled, closed: closed)
        viewModel.cancelTapped()
        #expect(closed.count == 1 && controlled.sent.withLock { $0.isEmpty })
    }
}
