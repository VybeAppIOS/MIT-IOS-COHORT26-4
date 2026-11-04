import Foundation
import Models

/// A voice note as the bubble shows it. The chat screen fills `progress` and `isPlaying` from Core's `AudioPlayer`.
public struct VoiceNoteData: Hashable, Sendable {
    /// "0:12" (built with `Duration.formatted(.time(pattern: .minuteSecond))`).
    public var durationText: String
    public var progress: Double
    public var isPlaying: Bool
    /// Loudness from 0 to 1 for the waveform bars; empty draws flat bars.
    public var levels: [Float]

    public init(durationText: String, progress: Double = 0, isPlaying: Bool = false, levels: [Float] = []) {
        self.durationText = durationText
        self.progress = progress
        self.isPlaying = isPlaying
        self.levels = levels
    }

    /// "0:12" for a length in seconds.
    public static func durationText(seconds: Int) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond))
    }
}

/// A poll ("I'm in" / "Not for me") as the bubble shows it. Polls live in group chats only, never inside a Hangout.
public struct PollData: Hashable, Sendable {
    public var question: String
    public var imInCount: Int
    public var notForMeCount: Int
    public var myVote: PollChoice?

    public init(question: String, imInCount: Int = 0, notForMeCount: Int = 0, myVote: PollChoice? = nil) {
        self.question = question
        self.imInCount = imInCount
        self.notForMeCount = notForMeCount
        self.myVote = myVote
    }

    public func count(for choice: PollChoice) -> Int {
        switch choice {
        case .imIn: imInCount
        case .notForMe: notForMeCount
        }
    }
}

/// One row of a conversation, already as display values. The chat ViewModel builds these from `Message`s.
public struct MessageRowData: Hashable, Sendable, Identifiable {
    public enum Content: Hashable, Sendable {
        case text(String)
        /// One or two photos.
        case photos([URL?])
        case hangout(HangoutCardData)
        case link(URL)
        case voice(VoiceNoteData)
        case poll(PollData)
        /// "This message was deleted".
        case deleted
        /// A line from the app, not a person: "Sample Aarav added Sample Isha".
        case system(String)
    }

    public enum Receipt: Hashable, Sendable {
        case sent
        case delivered
        case seen
    }

    public let id: String
    public var senderName: String
    public var isMine: Bool
    public var content: Content
    public var isEdited: Bool
    /// Only on my own last message.
    public var receipt: Receipt?
    /// False for the second and later messages of a run by the same person (grouping): no name, tighter spacing.
    public var startsGroup: Bool

    public init(
        id: String, senderName: String, isMine: Bool, content: Content, isEdited: Bool = false,
        receipt: Receipt? = nil, startsGroup: Bool = true
    ) {
        self.id = id
        self.senderName = senderName
        self.isMine = isMine
        self.content = content
        self.isEdited = isEdited
        self.receipt = receipt
        self.startsGroup = startsGroup
    }
}
