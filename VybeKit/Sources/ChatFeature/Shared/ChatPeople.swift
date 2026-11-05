import Core
import Foundation
import Models

/// Names for the people in chats, loaded once and shared by the Chat screens.
@MainActor
final class ChatPeople {
    private(set) var profiles: [UserID: UserProfile] = [:]

    /// Loads the profiles of `ids` that are not known yet. A person who cannot be loaded stays unnamed.
    func load(_ ids: some Sequence<UserID>, from repository: any ProfileRepository) async {
        for id in Set(ids) where profiles[id] == nil {
            profiles[id] = try? await repository.profile(id: id)
        }
    }

    func add(_ people: [UserProfile]) {
        for person in people { profiles[person.id] = person }
    }

    func name(_ id: UserID) -> String { profiles[id]?.displayName ?? "" }

    /// A direct message is titled with the other person's name; a group with its own name.
    func title(for conversation: Conversation, me myID: UserID?) -> String {
        if conversation.kind == .group { return conversation.name ?? "" }
        let other = conversation.memberIDs.first { $0 != myID }
        return other.map(name) ?? ""
    }
}

/// How a time in a chat is written: the clock time today, "Yesterday", or the day and month. Messages may show
/// clock times (the no-times rule is about visits to Spots).
enum ChatTime {
    static func text(for date: Date, now: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        let locale = Locale(identifier: "en_IN")
        if calendar.isDate(date, inSameDayAs: now) {
            return date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, calendar: calendar,
                                                   timeZone: calendar.timeZone))
        }
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)
        if let yesterday, calendar.isDate(date, inSameDayAs: yesterday) {
            return String(localized: "chat.time.yesterday", bundle: #bundle)
        }
        return date.formatted(Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .day().month(.abbreviated))
    }
}
