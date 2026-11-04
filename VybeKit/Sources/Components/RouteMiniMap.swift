import Design
import Models
import SwiftUI

/// A small drawing of a Hangout's route for a post without a photo: numbered dots for the Places, joined by straight
/// lines. It is drawn from the Places' coordinates only, never from a GPS track (`docs/RISKS.md` 3), and it is not a
/// map (no MapKit, no tiles), so it costs almost nothing in a scrolling feed.
public struct RouteMiniMap: View {
    private let points: [Coordinate]

    public init(points: [Coordinate]) {
        self.points = points
    }

    public var body: some View {
        Canvas { context, size in
            let placed = Self.layout(points, in: size, inset: Theme.Spacing.extraLarge)
            var line = Path()
            line.addLines(placed)
            context.stroke(line, with: .color(Theme.Color.accent),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [6, 6]))
            for (offset, point) in placed.enumerated() {
                let dot = CGRect(x: point.x - 12, y: point.y - 12, width: 24, height: 24)
                context.fill(Path(ellipseIn: dot), with: .color(Theme.Color.accent))
                context.draw(Text(offset + 1, format: .number).font(Theme.Font.caption2)
                    .foregroundStyle(Theme.Color.onAccent), at: point)
            }
        }
        .background(Theme.Color.surfaceRaised)
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: ComponentStrings.routeMap))
        .accessibilityAddTraits(.isImage)
    }

    /// Fits the coordinates into the drawing, keeping their shape (north up) and leaving a margin.
    /// One point sits in the middle; no points draw nothing.
    static func layout(_ coordinates: [Coordinate], in size: CGSize, inset: CGFloat) -> [CGPoint] {
        guard let first = coordinates.first else { return [] }
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let minLatitude = latitudes.min() ?? first.latitude
        let maxLatitude = latitudes.max() ?? first.latitude
        let minLongitude = longitudes.min() ?? first.longitude
        let maxLongitude = longitudes.max() ?? first.longitude
        let span = max(maxLatitude - minLatitude, maxLongitude - minLongitude)
        let usableWidth = max(0, size.width - 2 * inset)
        let usableHeight = max(0, size.height - 2 * inset)
        let scale = span > 0 ? min(usableWidth, usableHeight) / CGFloat(span) : 0
        let middleLatitude = (minLatitude + maxLatitude) / 2
        let middleLongitude = (minLongitude + maxLongitude) / 2
        return coordinates.map { coordinate in
            CGPoint(x: size.width / 2 + CGFloat(coordinate.longitude - middleLongitude) * scale,
                    y: size.height / 2 - CGFloat(coordinate.latitude - middleLatitude) * scale)
        }
    }
}

#if DEBUG
#Preview("Two EXAMPLE places") {
    RouteMiniMap(points: SampleData.places.map(\.coordinate))
        .aspectRatio(4 / 3, contentMode: .fit)
        .clipShape(.rect(cornerRadius: Theme.Radius.large))
        .padding(Theme.Spacing.large)
}

#Preview("Four points") {
    RouteMiniMap(points: [
        Coordinate(latitude: 18.5000, longitude: 73.8000), Coordinate(latitude: 18.5040, longitude: 73.8060),
        Coordinate(latitude: 18.5010, longitude: 73.8120), Coordinate(latitude: 18.4980, longitude: 73.8070)
    ])
    .aspectRatio(4 / 3, contentMode: .fit)
    .padding(Theme.Spacing.large)
}
#endif
