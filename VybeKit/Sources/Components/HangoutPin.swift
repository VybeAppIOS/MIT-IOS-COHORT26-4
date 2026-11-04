import Design
import Models
import SwiftUI

/// A Hangout on the Discover map: a round pin with a small photo, or the category symbol when there is no photo.
/// Picks have the accent ring. The selected pin grows (a plain fade with Reduce Motion). It is a plain view that
/// SC-D1 puts inside a MapKit `Annotation`; it never imports MapKit itself.
public struct HangoutPin: View {
    private let title: String
    private let category: PlaceCategory
    private let photoURL: URL?
    private let isPick: Bool
    private let isSelected: Bool
    @ScaledMetric(relativeTo: .body) private var diameter = 36.0

    public init(title: String, category: PlaceCategory, photoURL: URL? = nil, isPick: Bool = false,
                isSelected: Bool = false) {
        self.title = title
        self.category = category
        self.photoURL = photoURL
        self.isPick = isPick
        self.isSelected = isSelected
    }

    public var body: some View {
        face
            .frame(width: diameter, height: diameter)
            .clipShape(.circle)
            .overlay(Circle().strokeBorder(isPick ? Theme.Color.accent : Theme.Color.surface, lineWidth: 3))
            .scaleEffect(isSelected ? 1.3 : 1)
            .vybeAnimation(Theme.Motion.standard, value: isSelected)
            .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
            .contentShape(.circle)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: accessibilityText))
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder private var face: some View {
        if photoURL != nil {
            PlaceImage(url: photoURL, aspectRatio: 1)
        } else {
            ZStack {
                Circle().fill(isPick ? Theme.Color.accent : Theme.Color.surfaceRaised)
                Image(systemName: Self.symbol(for: category))
                    .font(Theme.Font.subheadline)
                    .foregroundStyle(isPick ? Theme.Color.onAccent : Theme.Color.textPrimary)
            }
        }
    }

    private var accessibilityText: String {
        var parts = [title, ComponentStrings.categoryName(category)]
        if isPick { parts.append(SharedStrings.badgePicks) }
        return parts.joined(separator: ", ")
    }

    /// The SF Symbol for each kind of Place (`frying.pan.fill` for food, `figure.hiking` for treks, …); `mappin` for a
    /// category this app version does not know.
    static func symbol(for category: PlaceCategory) -> String { symbols[category] ?? "mappin" }

    static let symbols: [PlaceCategory: String] = [
        .cafe: "cup.and.saucer.fill", .studyCafe: "cup.and.saucer.fill", .boardGameCafe: "cup.and.saucer.fill",
        .streetFood: "frying.pan.fill", .restaurant: "frying.pan.fill", .chaiTapri: "mug.fill",
        .dessert: "birthday.cake.fill", .juiceShakes: "takeoutbag.and.cup.and.straw.fill",
        .trek: "figure.hiking", .viewpointHill: "figure.hiking", .fort: "building.columns.fill",
        .heritageTemple: "building.columns.fill", .museum: "building.columns.fill", .lakeDam: "drop.fill",
        .waterfall: "drop.fill", .swimming: "drop.fill", .parkGarden: "tree.fill", .camping: "tree.fill",
        .gamingArcade: "gamecontroller.fill", .bowling: "gamecontroller.fill", .goKarting: "gamecontroller.fill",
        .trampoline: "gamecontroller.fill", .escapeRoom: "gamecontroller.fill", .karaoke: "music.mic",
        .cinema: "theatermasks.fill", .theatre: "theatermasks.fill", .comedyOpenMic: "theatermasks.fill",
        .liveMusic: "music.note", .events: "sparkles", .artGallery: "paintpalette.fill",
        .bookstoreLibrary: "books.vertical.fill", .library: "books.vertical.fill", .streetMarket: "bag.fill",
        .thrift: "bag.fill", .mall: "bag.fill", .sportsTurf: "figure.run", .cycling: "bicycle"
    ]
}

/// Several Hangouts too close to tell apart at this zoom: a bubble with the count. Tapping it zooms in (SC-D1).
public struct ClusterPin: View {
    private let count: Int
    @ScaledMetric(relativeTo: .body) private var diameter = 40.0

    public init(count: Int) {
        self.count = count
    }

    public var body: some View {
        Text(verbatim: DisplayFormat.compactCount(count))
            .font(Theme.Font.subheadline.weight(.bold))
            .foregroundStyle(Theme.Color.onAccent)
            .minimumScaleFactor(0.6)
            .padding(Theme.Spacing.tiny)
            .frame(minWidth: diameter, minHeight: diameter)
            .background(Theme.Color.accent, in: .circle)
            .overlay(Circle().strokeBorder(Theme.Color.surface, lineWidth: 3))
            .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
            .contentShape(.circle)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: ComponentStrings.clusterLabel(count)))
            .accessibilityAddTraits(.isButton)
    }
}

#if DEBUG
#Preview("Pins") {
    HStack(spacing: Theme.Spacing.large) {
        HangoutPin(title: "EXAMPLE Evening Hangout", category: .cafe)
        HangoutPin(title: "EXAMPLE Evening Hangout", category: .trek, isPick: true)
        HangoutPin(title: "EXAMPLE Evening Hangout", category: .parkGarden, isSelected: true)
        ClusterPin(count: 2)
        ClusterPin(count: 25)
    }
    .padding(Theme.Spacing.huge)
    .background(Theme.Color.surfaceRaised)
}

#Preview("Large text") {
    HStack(spacing: Theme.Spacing.large) {
        HangoutPin(title: "EXAMPLE Evening Hangout", category: .fort, isPick: true, isSelected: true)
        ClusterPin(count: 1_200)
    }
    .padding(Theme.Spacing.huge)
    .dynamicTypeSize(.accessibility3)
}
#endif
