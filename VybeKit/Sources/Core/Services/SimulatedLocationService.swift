import Foundation
import Models

/// Replays a route at walking speed, for desk demos, previews and tests. No GPS, no permission prompt.
/// Time is injected: `sleep` waits between samples and `now` stamps them, so a test can use a fake clock and finish
/// instantly while still checking the exact pace.
public struct SimulatedLocationService: LocationService {
    /// A relaxed walk: 1.4 metres per second.
    public static let walkingSpeed = 1.4

    public let route: [Coordinate]
    public let metersPerSecond: Double
    public let interval: Duration
    private let now: @Sendable () -> Date
    private let sleep: @Sendable (Duration) async throws -> Void

    public init(
        route: [Coordinate], metersPerSecond: Double = walkingSpeed, interval: Duration = .seconds(1),
        now: @escaping @Sendable () -> Date = { Date() },
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.route = route
        self.metersPerSecond = metersPerSecond
        self.interval = interval
        self.now = now
        self.sleep = sleep
    }

    public var authorization: LocationAuthorization { .whenInUse }

    public func requestWhenInUse() {}

    /// The first sample is the start of the route, then one every `interval`, each one `metersPerSecond * interval`
    /// further along the path. The last sample is the end of the route, then the stream ends.
    public func updates() -> AsyncStream<LocationSample> {
        let path = RoutePath(route)
        let step = metersPerSecond * interval.seconds
        let (now, sleep, interval) = (now, sleep, interval)
        return AsyncStream { continuation in
            let task = Task {
                guard !path.isEmpty, step > 0 else {
                    continuation.finish()
                    return
                }
                var travelled = 0.0
                while true {
                    let done = travelled >= path.length
                    continuation.yield(LocationSample(coordinate: path.coordinate(at: min(travelled, path.length)),
                                                      timestamp: now(), horizontalAccuracy: 5))
                    if done { break }
                    do { try await sleep(interval) } catch { break }
                    travelled += step
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

extension Duration {
    var seconds: Double {
        Double(components.seconds) + Double(components.attoseconds) / 1e18
    }
}

/// A route as a line: how long it is and where you are after walking so far along it.
struct RoutePath {
    private let points: [Coordinate]
    private let cumulative: [Double]
    var isEmpty: Bool { points.isEmpty }
    var length: Double { cumulative.last ?? 0 }

    init(_ points: [Coordinate]) {
        self.points = points
        var total = 0.0
        var running: [Double] = []
        for index in points.indices {
            if index > 0 { total += Self.meters(from: points[index - 1], to: points[index]) }
            running.append(total)
        }
        cumulative = running
    }

    /// The point `distance` metres along the route (clamped to its ends).
    func coordinate(at distance: Double) -> Coordinate {
        guard let first = points.first else { return Coordinate(latitude: 0, longitude: 0) }
        guard distance > 0, points.count > 1 else { return first }
        guard distance < length, let next = cumulative.firstIndex(where: { $0 >= distance }), next > 0 else {
            return points[points.count - 1]
        }
        let span = cumulative[next] - cumulative[next - 1]
        let fraction = span > 0 ? (distance - cumulative[next - 1]) / span : 0
        let before = points[next - 1]
        let after = points[next]
        return Coordinate(latitude: before.latitude + (after.latitude - before.latitude) * fraction,
                          longitude: before.longitude + (after.longitude - before.longitude) * fraction)
    }

    /// Straight-line distance in metres (haversine).
    static func meters(from first: Coordinate, to second: Coordinate) -> Double {
        let radius = 6_371_000.0
        let latitude1 = first.latitude * .pi / 180
        let latitude2 = second.latitude * .pi / 180
        let deltaLatitude = (second.latitude - first.latitude) * .pi / 180
        let deltaLongitude = (second.longitude - first.longitude) * .pi / 180
        let haversine = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(latitude1) * cos(latitude2) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        return radius * 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
    }
}

#if DEBUG
public extension SimulatedLocationService {
    /// A short walk between the two EXAMPLE places, for previews and desk demos before the real Kothrud walk
    /// (`Kothrud-Walk.gpx`, task X-9) exists.
    static var examplePreview: SimulatedLocationService {
        SimulatedLocationService(route: [SampleData.cafe.coordinate, SampleData.park.coordinate])
    }
}
#endif
