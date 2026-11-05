import Core
import Foundation
import Models

/// Which events may send a notification. The defaults (all on) are a proposal: see the WO-3 report.
struct NotificationChoices: Equatable, Sendable {
    var friendRequests = true
    var messages = true
    var likes = true
    var comments = true
    var reminders = true
}

/// One switch, ready to draw.
struct NotificationSwitch: Identifiable, Equatable {
    enum Kind: String, CaseIterable {
        case friendRequests
        case messages
        case likes
        case comments
        case reminders
    }

    let kind: Kind
    let title: String
    let isOn: Bool

    var id: Kind { kind }
}

/// ST4, Notifications. One switch per event. The system permission is **not** asked here: it is asked at the first
/// friend request or chat. Where the choices are kept is injected (`loadChoices` / `saveChoices`), because no shared
/// storage for them exists yet (see the WO-3 report); tests pass an in-memory pair.
@MainActor @Observable
final class NotificationsViewModel {
    private(set) var state: LoadState<[NotificationSwitch]> = .loading
    private(set) var saveFailed = false

    private var choices = NotificationChoices()
    private let loadChoices: @MainActor () async throws -> NotificationChoices
    private let saveChoices: @MainActor (NotificationChoices) async throws -> Void
    private var hasLoaded = false

    /// Cheap: nothing loads here (ADR 005).
    init(
        loadChoices: @escaping @MainActor () async throws -> NotificationChoices,
        saveChoices: @escaping @MainActor (NotificationChoices) async throws -> Void
    ) {
        self.loadChoices = loadChoices
        self.saveChoices = saveChoices
    }

    var title: String { String(localized: "profile.notifications.title", bundle: #bundle) }
    var footer: String { String(localized: "profile.notifications.footer", bundle: #bundle) }
    var errorText: String { String(localized: "profile.notifications.error", bundle: #bundle) }

    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    func reload() async { await fetch() }

    private func fetch() async {
        do {
            choices = try await loadChoices()
            hasLoaded = true
            state = .loaded(switches)
        } catch is CancellationError {
            return
        } catch {
            if case .loaded = state { return }
            state = .failed(AppError(error))
        }
    }

    private var switches: [NotificationSwitch] {
        NotificationSwitch.Kind.allCases.map { kind in
            let key = String.LocalizationValue(stringLiteral: "profile.notifications." + kind.rawValue)
            return NotificationSwitch(kind: kind, title: String(localized: key, bundle: #bundle),
                                      isOn: value(for: kind))
        }
    }

    private func value(for kind: NotificationSwitch.Kind) -> Bool {
        switch kind {
        case .friendRequests: choices.friendRequests
        case .messages: choices.messages
        case .likes: choices.likes
        case .comments: choices.comments
        case .reminders: choices.reminders
        }
    }

    // MARK: What the person does

    /// Flips one switch and saves. If saving fails, the switch goes back and a note says so.
    func setSwitch(_ kind: NotificationSwitch.Kind, isOn: Bool) async {
        let before = choices
        switch kind {
        case .friendRequests: choices.friendRequests = isOn
        case .messages: choices.messages = isOn
        case .likes: choices.likes = isOn
        case .comments: choices.comments = isOn
        case .reminders: choices.reminders = isOn
        }
        state = .loaded(switches)
        do {
            try await saveChoices(choices)
            saveFailed = false
        } catch is CancellationError {
            return
        } catch {
            choices = before
            state = .loaded(switches)
            saveFailed = true
        }
    }
}
