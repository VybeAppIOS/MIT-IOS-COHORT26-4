import Foundation
import Models

/// One Hangout's position on the map (its first Spot).
struct MapPoint: Equatable, Sendable {
    let id: HangoutID
    let coordinate: Coordinate
}

/// Several Hangouts too close to tell apart at the current zoom, drawn as one bubble with a count.
struct PinCluster: Equatable, Sendable, Identifiable {
    let ids: [HangoutID]
    /// The average position of its Hangouts.
    let center: Coordinate
    /// The box around its Hangouts, so a tap can zoom in until they separate.
    let minLatitude: Double
    let maxLatitude: Double
    let minLongitude: Double
    let maxLongitude: Double

    /// Also the `Map(selection:)` tag: "cluster-" plus its first Hangout ID and its size.
    var id: String { "cluster-\(ids.first?.rawValue ?? "")-\(ids.count)" }
}

/// What the map draws: a single Hangout pin or a cluster.
enum MapMarker: Equatable, Sendable, Identifiable {
    case pin(MapPoint)
    case cluster(PinCluster)

    /// Also the `Map(selection:)` tag: the Hangout ID for a pin, the cluster's own ID for a cluster.
    var id: String {
        switch self {
        case .pin(let point): point.id.rawValue
        case .cluster(let cluster): cluster.id
        }
    }
}

/// Grid clustering (ARCHITECTURE 4: SwiftUI `Map` cannot cluster). The visible area is cut into a grid about
/// `cellsAcross` cells wide; Hangouts in the same cell become one cluster. Zooming in shrinks the cells, so clusters
/// split; zooming out grows them, so pins merge. Works on plain `Coordinate`s: the View converts the map camera.
///
/// A grid can put two very close pins on either side of a cell edge; at the next zoom step they join. That is the
/// known trade-off of grid clustering, and fine for a first version (ARCHITECTURE 4).
enum PinClusterer {
    static let cellsAcross = 8.0

    static func cluster(_ points: [MapPoint], latitudeSpan: Double, longitudeSpan: Double) -> [MapMarker] {
        guard latitudeSpan > 0, longitudeSpan > 0 else { return points.map(MapMarker.pin) }
        let cellHeight = latitudeSpan / cellsAcross
        let cellWidth = longitudeSpan / cellsAcross

        var cells: [GridCell: [MapPoint]] = [:]
        for point in points {
            let cell = GridCell(row: Int((point.coordinate.latitude / cellHeight).rounded(.down)),
                                column: Int((point.coordinate.longitude / cellWidth).rounded(.down)))
            cells[cell, default: []].append(point)
        }

        // Sorted by cell, so the same input always gives the same order (stable tests, no flicker).
        return cells.sorted { $0.key < $1.key }.map { _, members in
            guard members.count > 1 else { return .pin(members[0]) }
            let latitudes = members.map(\.coordinate.latitude)
            let longitudes = members.map(\.coordinate.longitude)
            return .cluster(PinCluster(
                ids: members.map(\.id),
                center: Coordinate(latitude: latitudes.reduce(0, +) / Double(members.count),
                                   longitude: longitudes.reduce(0, +) / Double(members.count)),
                minLatitude: latitudes.min() ?? 0, maxLatitude: latitudes.max() ?? 0,
                minLongitude: longitudes.min() ?? 0, maxLongitude: longitudes.max() ?? 0))
        }
    }

    private struct GridCell: Hashable, Comparable {
        let row: Int
        let column: Int

        static func < (lhs: GridCell, rhs: GridCell) -> Bool {
            (lhs.row, lhs.column) < (rhs.row, rhs.column)
        }
    }
}
