import Foundation

/// Words that several features use. A feature cannot look up a key in Design's catalog by itself (each target's
/// `String(localized:)` reads its own bundle), so Design exposes each shared word as a value.
public enum SharedStrings {
    public static var cancel: String { String(localized: "common.cancel", bundle: #bundle) }
}

/// Words for the shared components (Badges, SafetyNote). Components has no catalog of its own yet, so the
/// words live in Design's catalog under `component.<name>.<key>` and Components shows them with `Text(verbatim:)`.
public extension SharedStrings {
    static var badgePicks: String { String(localized: "component.badge.picks", bundle: #bundle) }
    static var badgeSaved: String { String(localized: "component.badge.saved", bundle: #bundle) }
    static var badgeDraft: String { String(localized: "component.badge.draft", bundle: #bundle) }
    static var badgeScheduled: String { String(localized: "component.badge.scheduled", bundle: #bundle) }
    static var badgeLive: String { String(localized: "component.badge.live", bundle: #bundle) }
    static var badgeDone: String { String(localized: "component.badge.done", bundle: #bundle) }
    static var badgeClosed: String { String(localized: "component.badge.closed", bundle: #bundle) }
    static var safetyNotePrefixNote: String { String(localized: "component.safetynote.prefixNote", bundle: #bundle) }
    static var safetyNotePrefixWarning: String {
        String(localized: "component.safetynote.prefixWarning", bundle: #bundle)
    }
    /// Draft wording; the team approves the final text (docs/RISKS.md).
    static var safetyNoteMonsoon: String { String(localized: "component.safetynote.monsoon", bundle: #bundle) }
}
