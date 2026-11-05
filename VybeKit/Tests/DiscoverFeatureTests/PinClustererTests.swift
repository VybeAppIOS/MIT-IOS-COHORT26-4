import Models
import Testing
@testable import DiscoverFeature

/// Grid clustering (task SC-D1): same point, far points, zoom change, and the edges.
/// `@MainActor` like the feature itself (features are main-actor by default, ADR 001).
@MainActor
struct PinClustererTests {
    private func point(_ id: String, _ latitude: Double, _ longitude: Double) -> MapPoint {
        MapPoint(id: HangoutID(id), coordinate: Coordinate(latitude: latitude, longitude: longitude))
    }

    @Test func pinsAtTheSamePointBecomeOneCluster() throws {
        let points = [point("a", 18.5, 73.8), point("b", 18.5, 73.8), point("c", 18.5, 73.8)]
        let markers = PinClusterer.cluster(points, latitudeSpan: 0.1, longitudeSpan: 0.1)
        #expect(markers.count == 1)
        guard case .cluster(let cluster) = try #require(markers.first) else {
            Issue.record("expected a cluster")
            return
        }
        #expect(Set(cluster.ids) == ["a", "b", "c"])
        #expect(cluster.center == Coordinate(latitude: 18.5, longitude: 73.8))
    }

    @Test func farApartPinsStaySeparate() {
        let points = [point("kothrud", 18.50, 73.80), point("far", 19.50, 74.80)]
        let markers = PinClusterer.cluster(points, latitudeSpan: 0.1, longitudeSpan: 0.1)
        #expect(markers.count == 2)
        #expect(markers.allSatisfy { if case .pin = $0 { true } else { false } })
    }

    @Test func zoomingInSplitsAClusterAndZoomingOutMergesIt() {
        // About 600 m apart: one cell when the map shows 1° (cells of 0.125°), two cells at 0.01° (0.00125°).
        let points = [point("a", 18.501, 73.801), point("b", 18.505, 73.805)]
        let zoomedOut = PinClusterer.cluster(points, latitudeSpan: 1, longitudeSpan: 1)
        let zoomedIn = PinClusterer.cluster(points, latitudeSpan: 0.01, longitudeSpan: 0.01)
        #expect(zoomedOut.count == 1)
        #expect(zoomedIn.count == 2)
    }

    @Test func aClusterKnowsTheBoxAroundItsPins() throws {
        let points = [point("a", 18.501, 73.801), point("b", 18.505, 73.805)]
        guard case .cluster(let cluster) = try #require(
            PinClusterer.cluster(points, latitudeSpan: 1, longitudeSpan: 1).first) else {
            Issue.record("expected a cluster")
            return
        }
        #expect(cluster.minLatitude == 18.501)
        #expect(cluster.maxLatitude == 18.505)
        #expect(cluster.minLongitude == 73.801)
        #expect(cluster.maxLongitude == 73.805)
    }

    @Test func noPinsGiveNoMarkers() {
        #expect(PinClusterer.cluster([], latitudeSpan: 1, longitudeSpan: 1).isEmpty)
    }

    @Test func aSinglePinStaysAPin() {
        let only = point("a", 18.5, 73.8)
        #expect(PinClusterer.cluster([only], latitudeSpan: 1, longitudeSpan: 1) == [.pin(only)])
    }

    @Test func aZeroSpanNeverClusters() {
        let points = [point("a", 18.5, 73.8), point("b", 18.5, 73.8)]
        #expect(PinClusterer.cluster(points, latitudeSpan: 0, longitudeSpan: 0).count == 2)
    }

    @Test func theSameInputGivesTheSameOrder() {
        let points = [point("a", 18.50, 73.80), point("b", 19.50, 74.80), point("c", 17.50, 72.80)]
        let first = PinClusterer.cluster(points, latitudeSpan: 0.1, longitudeSpan: 0.1)
        let second = PinClusterer.cluster(points.reversed(), latitudeSpan: 0.1, longitudeSpan: 0.1)
        #expect(first == second)
    }
}
