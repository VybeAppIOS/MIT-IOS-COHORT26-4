import Components
import Core
import Design
import Foundation
import Models
import Observation

/// Poll composer (SC-CH6): a question with the two fixed answers "I'm in" and "Not for me". Send posts a poll message
/// in a group chat. Voting happens in the chat, never inside a Hangout.
@MainActor @Observable
final class PollViewModel {
    static let questionLimit = 140

    var question = ""
    private(set) var isSending = false
    /// A short message to show once. The View clears it.
    var notice: String?

    private let conversationID: ConversationID
    private let chat: any ChatRepository
    private let network: NetworkMonitor
    private let onClose: @MainActor () -> Void

    /// Cheap: nothing loads here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(
        conversationID: ConversationID, chat: any ChatRepository, network: NetworkMonitor,
        onClose: @escaping @MainActor () -> Void
    ) {
        self.conversationID = conversationID
        self.chat = chat
        self.network = network
        self.onClose = onClose
    }

    // MARK: Words

    var title: String { String(localized: "chat.poll.title", bundle: #bundle) }
    var questionLabel: String { String(localized: "chat.poll.question", bundle: #bundle) }
    var placeholder: String { String(localized: "chat.poll.placeholder", bundle: #bundle) }
    var optionsHeader: String { String(localized: "chat.poll.options", bundle: #bundle) }
    var sendLabel: String { String(localized: "chat.poll.send", bundle: #bundle) }
    var cancelLabel: String { String(localized: "chat.poll.cancel", bundle: #bundle) }
    var okLabel: String { String(localized: "chat.poll.ok", bundle: #bundle) }

    /// The only two answers, in this order. Polls never have other options.
    var options: [String] { [ComponentStrings.pollImIn, ComponentStrings.pollNotForMe] }

    // MARK: Rules

    private var trimmed: String { question.trimmingCharacters(in: .whitespacesAndNewlines) }
    var canSend: Bool {
        !trimmed.isEmpty && question.count <= Self.questionLimit && !isSending && !network.isOffline
    }

    func cancelTapped() { onClose() }

    func sendTapped() async {
        guard canSend else { return }
        isSending = true
        defer { isSending = false }
        do {
            _ = try await chat.send(.poll(question: trimmed), in: conversationID)
            onClose()
        } catch is CancellationError {
            return
        } catch {
            notice = AppError(error).message   // the question stays, so the person can try again
        }
    }
}
