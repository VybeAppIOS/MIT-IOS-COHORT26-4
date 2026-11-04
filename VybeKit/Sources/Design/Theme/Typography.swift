import SwiftUI

public extension Theme {
    /// Text styles only, so every size follows Dynamic Type. Never use `.system(size:)`.
    enum Font {
        public static let largeTitle = SwiftUI.Font.largeTitle
        public static let title = SwiftUI.Font.title
        public static let title2 = SwiftUI.Font.title2
        public static let title3 = SwiftUI.Font.title3
        public static let headline = SwiftUI.Font.headline
        public static let subheadline = SwiftUI.Font.subheadline
        public static let body = SwiftUI.Font.body
        public static let callout = SwiftUI.Font.callout
        public static let footnote = SwiftUI.Font.footnote
        public static let caption = SwiftUI.Font.caption
        public static let caption2 = SwiftUI.Font.caption2
    }
}
