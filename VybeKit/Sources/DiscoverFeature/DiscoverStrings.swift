import Foundation

/// Strings owned by this feature. Each lookup names `bundle: #bundle`, so it reads this target's own catalog
/// (`Resources/Localizable.xcstrings`) and not the app's. Proof for task X-3.
enum DiscoverStrings {
    static var title: String { String(localized: "discover.title", bundle: #bundle) }
}
