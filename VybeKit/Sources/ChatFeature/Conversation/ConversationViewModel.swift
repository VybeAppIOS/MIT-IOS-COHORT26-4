import Components
import Core
import Design
import Foundation
import Models
import Observation

/// What the Conversation needs from a voice recorder. `AudioRecorder` is the real one; tests use a fake.
protocol VoiceRecording: Sendable {
    func start() async throws
    func stop() async throws -> VoiceNote
    func cancel() async
}

/// The real recorder from Core, behind the small protocol above.
struct SystemVoiceRecorder: VoiceRecording {
    let recorder = AudioRecorder()
    func start() async throws { try await recorder.start() }
    func stop() async throws -> VoiceNote { try await recorder.stop() }
    func cancel() async { await recorder.cancel() }
}

/// Builds the Poll composer for this chat. `onClose` is called when the sheet should close.
typealias PollFactory = @MainActor (ConversationID, @escaping @MainActor () -> Void) -> PollViewModel

/// The view-ready values of the Conversation (never a raw model).
struct ConversationContent: Equatable {
    var title: String
    var isGroup: Bool
    var rows: [MessageRowData]
    /// A group of fewer than 3 people is read-only.
    var isReadOnly: Bool
    /// The admin muted me: I can read, but the composer is off.
    var isMuted = false
}

/// A Hangout from Saved that can be sent into the chat.
struct SavedHangoutChoice: Identifiable, Equatable {
    let id: HangoutID
    let title: String
}

/// Conversation (SC-CH2): the messages of one chat, newest at the bottom, and a composer. Text, Hangouts from Saved,
/// polls (groups only) and voice notes; edit and delete your own text; report any message; read receipts always on.
/// New messages arrive through the repository's stream, which stops when the screen goes away.
@MainActor @Observable
final class ConversationViewModel {
    static let groupGap: TimeInterval = 5 * 60

    private(set) var state: LoadState<ConversationContent> = .loading
    var draft = ""
    var editingID: MessageID?
    var isRecording = false
    private(set) var isSending = false
    /// The message waiting for a "Delete for everyone?" answer.
    var deletingID: MessageID?
    /// True while the Poll composer sheet is open.
    var isShowingPoll = false
    var isShowingSaved = false
    var saved: [SavedHangoutChoice] = []
    /// A short message to show once. The View clears it.
    var notice: String?
    /// The full-screen photo viewer, when a photo is open.
    var viewer: PhotoViewerItem?
    /// True while picked photos are being made safe, saved and sent.
    var isSendingPhotos = false

    let conversationID: ConversationID
    let chat: any ChatRepository
    let profiles: any ProfileRepository
    let hangouts: any HangoutRepository
    let photoStore: any PhotoStore
    let processor: PhotoProcessor
    let libraryStore: LibraryStore
    let session: SessionStore
    let badges: BadgeStore
    let network: NetworkMonitor
    let router: Router
    let now: @Sendable () -> Date
    let recorder: any VoiceRecording
    let player: AudioPlayer
    let makePoll: PollFactory
    var conversation: Conversation?
    var messages: [Message] = []
    var people = ChatPeople()
    var votes: [MessageID: [PollVote]] = [:]
    var cards: [HangoutID: HangoutCardData] = [:]
    var playingID: MessageID?
    var hasMarkedRead = false
    /// Everyone in this chat with their role, read time and mute (reloaded whenever the messages change).
    var memberships: [Membership] = []
    var isMuted = false

    /// Cheap: no loading here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(
        conversationID: ConversationID, chat: any ChatRepository, profiles: any ProfileRepository,
        hangouts: any HangoutRepository, photos: any PhotoStore, libraryStore: LibraryStore, session: SessionStore,
        badges: BadgeStore, network: NetworkMonitor, router: Router, now: @escaping @Sendable () -> Date,
        recorder: any VoiceRecording, player: AudioPlayer, makePoll: @escaping PollFactory,
        processor: PhotoProcessor = PhotoProcessor()
    ) {
        self.conversationID = conversationID
        self.chat = chat
        self.profiles = profiles
        self.hangouts = hangouts
        self.photoStore = photos
        self.processor = processor
        self.libraryStore = libraryStore
        self.session = session
        self.badges = badges
        self.network = network
        self.router = router
        self.now = now
        self.recorder = recorder
        self.player = player
        self.makePoll = makePoll
    }

    // MARK: Loading and the live stream

    /// Called by `.task`. Loads the chat, then listens for new messages until the screen goes away: cancelling the
    /// task (leaving the screen) ends the loop, and that is not an error (ADR 005).
    func run() async {
        do {
            guard let found = try await chat.conversations().first(where: { $0.id == conversationID }) else {
                state = .empty
                return
            }
            conversation = found
            await people.load(found.memberIDs, from: profiles)
            await loadMemberships(in: found)
            for try await batch in chat.messages(in: conversationID) {
                messages = batch
                await loadVotesAndCards()
                await loadMemberships(in: found)   // read times move whenever the messages do, so "Seen" stays right
                publish()
                await markReadOnce()
            }
        } catch is CancellationError {
            return
        } catch {
            if case .loaded(let content, _) = state {
                state = .loaded(content, isStale: true)   // a broken stream keeps the messages on screen
            } else {
                state = .failed(AppError(error))   // only a first load can fail
            }
        }
    }

    /// The Retry button.
    func retry() async { await run() }

    /// Who is in the chat and when they last read it. This tells me whether the admin has muted me in this group and
    /// whether anyone has seen my last message. A failed lookup keeps what was known before (so nothing flips to
    /// muted or seen by mistake); a muted person's message is still refused by the repository, with a notice.
    private func loadMemberships(in conversation: Conversation) async {
        memberships = (try? await chat.memberships(in: conversationID)) ?? memberships
        guard conversation.kind == .group, let myID = session.currentUser?.id else {
            isMuted = false
            return
        }
        isMuted = memberships.first { $0.userID == myID }?.mutedAt != nil
    }

    /// The latest time any other active member (not someone I blocked) read this chat.
    private func othersLastReadAt(myID: UserID?) -> Date? {
        memberships
            .filter { $0.userID != myID && $0.status == .active && !session.isBlocked($0.userID) }
            .compactMap(\.lastReadAt)
            .max()
    }

    private func loadVotesAndCards() async {
        for message in messages {
            switch message.payload {
            case .poll where votes[message.id] == nil:
                votes[message.id] = (try? await chat.votes(for: message.id)) ?? []
            case .hangout(let id) where cards[id] == nil:
                if let hangout = try? await hangouts.hangout(id: id) {
                    cards[id] = HangoutCardData(hangout, coverURL: nil, isSaved: libraryStore.isSaved(id))
                }
            default: break
            }
        }
    }

    private func markReadOnce() async {
        guard !hasMarkedRead else { return }
        hasMarkedRead = true
        let unread = (try? await chat.unreadCounts())?[conversationID] ?? 0
        try? await chat.markRead(conversationID)
        badges.chatWasRead(unread: unread)
    }

    func publish() {
        guard let conversation else { return }
        let myID = session.currentUser?.id
        let visible = messages.filter { !session.isBlocked($0.senderID) }   // a blocked person's messages are hidden
        let othersRead = othersLastReadAt(myID: myID)
        let rows = visible.enumerated().map { index, message in
            row(for: message, previous: index > 0 ? visible[index - 1] : nil, isLast: index == visible.count - 1,
                myID: myID, othersLastReadAt: othersRead)
        }
        let title = people.title(for: conversation, me: myID)
        let content = ConversationContent(
            title: title, isGroup: conversation.kind == .group, rows: rows,
            isReadOnly: conversation.kind == .group && conversation.memberIDs.count < 3, isMuted: isMuted)
        var stale = false
        if case .loaded(_, let wasStale) = state { stale = wasStale }
        state = .loaded(content, isStale: stale)
    }

    // MARK: Building rows

    private func row(
        for message: Message, previous: Message?, isLast: Bool, myID: UserID?, othersLastReadAt: Date?
    ) -> MessageRowData {
        let isMine = message.senderID == myID
        let startsGroup = previous == nil || previous?.senderID != message.senderID
            || message.createdAt.timeIntervalSince(previous?.createdAt ?? .distantPast) > Self.groupGap
        return MessageRowData(
            id: message.id.rawValue, senderName: isMine ? ComponentStrings.you : people.name(message.senderID),
            isMine: isMine, content: content(for: message, myID: myID), isEdited: message.editedAt != nil,
            receipt: isMine && isLast ? Self.receipt(for: message, othersLastReadAt: othersLastReadAt) : nil,
            startsGroup: startsGroup)
    }

    /// "Seen" when someone else has read up to this message, otherwise "Delivered". Read receipts are always on.
    /// `othersLastReadAt` is the newest read time among the other members (nil when nobody has read the chat).
    static func receipt(for message: Message, othersLastReadAt: Date?) -> MessageRowData.Receipt {
        if let readAt = othersLastReadAt, readAt >= message.createdAt { return .seen }
        return .delivered
    }

    private func content(for message: Message, myID: UserID?) -> MessageRowData.Content {
        if message.deletedAt != nil { return .deleted }
        switch message.payload {
        case .text(let text): return .text(text)
        case .photos(let photos): return .photos(photos.map { photoStore.url(for: $0) })
        case .hangout(let id):
            if let card = cards[id] { return .hangout(card) }
            return .text(String(localized: "chat.conversation.hangoutMissing", bundle: #bundle))
        case .link(let url): return .link(url)
        case .voice(_, let seconds):
            return .voice(VoiceNoteData(
                durationText: VoiceNoteData.durationText(seconds: seconds),
                isPlaying: playingID == message.id && player.isPlaying))
        case .poll(let question): return .poll(pollData(question, message.id, myID: myID))
        case .unsupported: return .text(String(localized: "chat.conversation.unsupported", bundle: #bundle))
        }
    }

    private func pollData(_ question: String, _ id: MessageID, myID: UserID?) -> PollData {
        let all = votes[id] ?? []
        return PollData(
            question: question, imInCount: all.filter { $0.choice == .imIn }.count,
            notForMeCount: all.filter { $0.choice == .notForMe }.count,
            myVote: all.first { $0.userID == myID }?.choice)
    }

    // MARK: Sending

    func sendTapped() async {
        guard canSendDraft else { return }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        isSending = true
        defer { isSending = false }
        do {
            if let editing = editingID {
                try await chat.edit(editing, text: text)
                editingID = nil
            } else {
                _ = try await chat.send(.text(text), in: conversationID)
            }
            draft = ""
        } catch is CancellationError {
            return
        } catch {
            notice = AppError(error).message   // the text stays in the box, so the person can try again
        }
    }

    func sendHangout(_ id: HangoutID) async {
        guard canWrite else { return }
        isShowingSaved = false
        do {
            _ = try await chat.send(.hangout(id), in: conversationID)
        } catch is CancellationError {
            return
        } catch {
            notice = AppError(error).message
        }
    }

    func hangoutTapped() async {
        await libraryStore.ensureLoaded()
        var choices: [SavedHangoutChoice] = []
        for id in libraryStore.savedHangoutIDs {
            if let hangout = try? await hangouts.hangout(id: id) {
                choices.append(SavedHangoutChoice(id: id, title: hangout.title))
            }
        }
        saved = choices
        isShowingSaved = true
    }

    func pollTapped() { if canStartPoll, canWrite { isShowingPoll = true } }

    func makePollViewModel() -> PollViewModel {
        makePoll(conversationID) { [weak self] in self?.isShowingPoll = false }
    }

    // MARK: Polls, links, Hangouts

    func vote(_ choice: PollChoice, on rowID: String) async {
        guard let message = message(rowID), canWrite else { return }
        do {
            try await chat.vote(choice, on: message.id)
            votes[message.id] = (try? await chat.votes(for: message.id)) ?? votes[message.id]
            publish()
        } catch is CancellationError {
            return
        } catch {
            notice = AppError(error).message
        }
    }

    func openHangout(_ id: HangoutID) { router.open(.hangout(id)) }

    // MARK: Header

    /// A group opens Group info; a direct message opens the other person's profile.
    func headerTapped() {
        guard let conversation else { return }
        if conversation.kind == .group {
            router.open(.groupInfo(conversationID))
        } else if let other = conversation.memberIDs.first(where: { $0 != session.currentUser?.id }) {
            router.open(.profile(other))
        }
    }
}
