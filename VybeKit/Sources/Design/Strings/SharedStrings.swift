import Foundation

/// Words that several features use. A feature cannot look up a key in Design's catalog by itself (each target's
/// `String(localized:)` reads its own bundle), so Design exposes each shared word as a value.
public enum SharedStrings {
    public static var cancel: String { String(localized: "common.cancel", bundle: #bundle) }
}
