import SwiftUI

public extension Theme {
    /// Semantic colours. Light only. Values live in `Resources/Colors.xcassets`, never in code.
    enum Color {
        public static let surface = SwiftUI.Color("Surface", bundle: .module)
        public static let surfaceRaised = SwiftUI.Color("SurfaceRaised", bundle: .module)
        public static let textPrimary = SwiftUI.Color("TextPrimary", bundle: .module)
        public static let textSecondary = SwiftUI.Color("TextSecondary", bundle: .module)
        public static let accent = SwiftUI.Color("Accent", bundle: .module)
        public static let onAccent = SwiftUI.Color("OnAccent", bundle: .module)
        public static let positive = SwiftUI.Color("Positive", bundle: .module)
        public static let warning = SwiftUI.Color("Warning", bundle: .module)
        public static let critical = SwiftUI.Color("Critical", bundle: .module)
        public static let separator = SwiftUI.Color("Separator", bundle: .module)
        public static let scrim = SwiftUI.Color("Scrim", bundle: .module)
    }
}
