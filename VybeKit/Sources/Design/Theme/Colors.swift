import Models
import SwiftUI

public extension Theme {
    /// Semantic colours, light and dark. Values live in `Resources/Colors.xcassets`, never in code, so one asset edit
    /// restyles the app.
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

        /// White text and icons on a photo with a dark scrim. Fixed in both appearances (`onAccent` flips in dark).
        public static let onPhoto = SwiftUI.Color("OnPhoto", bundle: .module)

        /// Dark text for bright fills. Unlike `textPrimary` it stays dark in both appearances, because the tints below
        /// stay bright in both.
        public static let ink = SwiftUI.Color("Ink", bundle: .module)

        // Bright tints for energy: category chips, empty-photo cards, small highlights. They are fills, not text
        // colours: always put `ink` on them, never white and never `textPrimary` (it turns light in dark mode).
        public static let sunset = SwiftUI.Color("Sunset", bundle: .module)
        public static let sun = SwiftUI.Color("Sun", bundle: .module)
        public static let lime = SwiftUI.Color("Lime", bundle: .module)
        public static let lilac = SwiftUI.Color("Lilac", bundle: .module)
        public static let pink = SwiftUI.Color("Pink", bundle: .module)
        public static let mint = SwiftUI.Color("Mint", bundle: .module)
        public static let sky = SwiftUI.Color("Sky", bundle: .module)

        /// One tint per group of Place categories, so a card or chip says what kind of place it is at a glance.
        public static func category(_ category: PlaceCategory) -> SwiftUI.Color {
            switch category {
            case .cafe, .chaiTapri, .restaurant, .streetFood, .juiceShakes, .boardGameCafe, .studyCafe: sunset
            case .dessert, .karaoke: pink
            case .parkGarden, .lakeDam, .waterfall, .camping, .cycling: mint
            case .trek, .fort, .viewpointHill, .swimming: sky
            case .museum, .heritageTemple, .artGallery, .theatre, .bookstoreLibrary, .library, .cinema,
                 .comedyOpenMic, .liveMusic, .events: lilac
            case .gamingArcade, .bowling, .goKarting, .trampoline, .escapeRoom, .sportsTurf: lime
            case .streetMarket, .thrift, .mall: sun
            case .unknown: sun
            }
        }
    }
}
