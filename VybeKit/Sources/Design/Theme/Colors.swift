import Models
import SwiftUI
import UIKit

public extension Theme {
    /// Semantic colours, light and dark. Values live in `Resources/Colors.xcassets`, never in code, so one asset edit
    /// restyles the app.
    enum Color {
        /// The colour from the asset catalog, for the current light or dark appearance. If the catalog cannot be read
        /// (an older iOS than the Xcode that built it), the generated copy in `ColorFallbacks` is used instead, so the
        /// app never draws invisible text. Never edit colours here: edit `Colors.xcassets`.
        static func named(_ name: String) -> SwiftUI.Color {
            SwiftUI.Color(uiColor: UIColor { traits in
                if let color = UIColor(named: name, in: .module, compatibleWith: traits) { return color }
                guard let pair = ColorFallbacks.pairs[name] else { return .magenta }   // a missing name is a bug
                let rgba = traits.userInterfaceStyle == .dark ? pair.dark : pair.light
                return UIColor(red: rgba[0], green: rgba[1], blue: rgba[2], alpha: rgba[3])
            })
        }

        public static let surface = named("Surface")
        public static let surfaceRaised = named("SurfaceRaised")
        public static let textPrimary = named("TextPrimary")
        public static let textSecondary = named("TextSecondary")
        public static let accent = named("Accent")
        public static let onAccent = named("OnAccent")
        public static let positive = named("Positive")
        public static let warning = named("Warning")
        public static let critical = named("Critical")
        public static let separator = named("Separator")
        public static let scrim = named("Scrim")

        /// White text and icons on a photo with a dark scrim. Fixed in both appearances (`onAccent` flips in dark).
        public static let onPhoto = named("OnPhoto")

        /// Dark text for bright fills. Unlike `textPrimary` it stays dark in both appearances, because the tints below
        /// stay bright in both.
        public static let ink = named("Ink")

        // Bright tints for energy: category chips, empty-photo cards, small highlights. They are fills, not text
        // colours: always put `ink` on them, never white and never `textPrimary` (it turns light in dark mode).
        public static let sunset = named("Sunset")
        public static let sun = named("Sun")
        public static let lime = named("Lime")
        public static let lilac = named("Lilac")
        public static let pink = named("Pink")
        public static let mint = named("Mint")
        public static let sky = named("Sky")

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
