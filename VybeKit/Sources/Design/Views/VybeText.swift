import SwiftUI

/// Display text for a component. A fixed label is looked up in a String Catalog; text that is already final
/// (data such as a tag, or a sentence a ViewModel built) is shown exactly as given.
enum VybeText {
    case fixed(LocalizedStringResource)
    case verbatim(String)

    var text: Text {
        switch self {
        case .fixed(let resource): Text(resource)
        case .verbatim(let string): Text(verbatim: string)
        }
    }

    /// The same words as a plain string, for accessibility labels.
    var plain: String {
        switch self {
        case .fixed(let resource): String(localized: resource)
        case .verbatim(let string): string
        }
    }
}
