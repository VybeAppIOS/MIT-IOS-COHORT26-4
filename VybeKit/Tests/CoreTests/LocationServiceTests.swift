import Foundation
import Models
import Synchronization
import Testing
@testable import Core

/// A clock the tests move by hand: the simulated walk "sleeps" by moving it, so nothing really waits.
private final class FakeClock: Sendable {
    private let current = Mutex(Date(timeIntervalSince1970: 1_793_700_000))
    private let sleeps = Mutex<[Duration]>([])
    var now: Date { current.withLock { $0 } }
    var sleepCount: Int { sleeps.withLock { $0.count } }

    func sleep(_ duration: Duration) async throws {
        try Task.checkCancellation()
        sleeps.withLock { $0.append(duration) }
        current.withLock { $0 = $0.addingTimeInterval(duration.seconds) }
    }
}

struct LocationServiceTests {
    private let start = Coordinate(latitude: 18.5000, longitude: 73.8000)
    /// About 133 m due north of `start`.
    private let north = Coordinate(latitude: 18.5012, longitude: 73.8000)

    private func service(
        _ route: [Coordinate], speed: Double = SimulatedLocationService.walkingSpeed, interval: Duration = .seconds(1),
        clock: FakeClock
    ) -> SimulatedLocationService {
        SimulatedLocationService(route: route, metersPerSecond: speed, interval: interval,
                                 now: { clock.now }, sleep: { try await clock.sleep($0) })
    }

    private func collect(_ stream: AsyncStream<LocationSample>) async -> [LocationSample] {
        var all: [LocationSample] = []
        for await sample in stream { all.append(sample) }
        return all
    }

    private func meters(_ first: Coordinate, _ second: Coordinate) -> Double {
        RoutePath.meters(from: first, to: second)
    }

    // MARK: Pace

    @Test func walksAtWalkingSpeedOneSamplePerSecond() async {
        let clock = FakeClock()
        let samples = await collect(service([start, north], clock: clock).updates())
        let length = meters(start, north)
        #expect(samples.first?.coordinate == start)
        #expect(samples.count == Int((length / 1.4).rounded(.up)) + 1)
        for pair in zip(samples, samples.dropFirst()).dropLast() {
            #expect(abs(meters(pair.0.coordinate, pair.1.coordinate) - 1.4) < 0.02)
            #expect(pair.1.timestamp.timeIntervalSince(pair.0.timestamp) == 1)
        }
    }

    @Test func theLastSampleIsTheEndOfTheRouteAndThenTheStreamEnds() async {
        let clock = FakeClock()
        let samples = await collect(service([start, north], clock: clock).updates())
        #expect(samples.last?.coordinate == north)
        #expect(clock.sleepCount == samples.count - 1)
    }

    @Test func aFasterWalkOrALongerIntervalCoversMoreGroundPerSample() async {
        let jog = await collect(service([start, north], speed: 2.8, clock: FakeClock()).updates())
        let walk = await collect(service([start, north], clock: FakeClock()).updates())
        #expect(jog.count < walk.count)
        let everyTwo = await collect(service([start, north], interval: .seconds(2), clock: FakeClock()).updates())
        #expect(abs(meters(everyTwo[0].coordinate, everyTwo[1].coordinate) - 2.8) < 0.02)
        #expect(everyTwo[1].timestamp.timeIntervalSince(everyTwo[0].timestamp) == 2)
    }

    @Test func aRouteWithACornerKeepsTheSamePaceAlongThePath() async {
        let east = Coordinate(latitude: 18.5012, longitude: 73.8012)
        let clock = FakeClock()
        let samples = await collect(service([start, north, east], clock: clock).updates())
        let total = meters(start, north) + meters(north, east)
        #expect(samples.count == Int((total / 1.4).rounded(.up)) + 1)
        #expect(samples.last?.coordinate == east)
        #expect(samples.contains { abs($0.coordinate.longitude - 73.8) > 0.00001 })   // it did turn east
    }

    @Test func everySampleStaysOnTheRoute() async {
        let samples = await collect(service([start, north], clock: FakeClock()).updates())
        for sample in samples {
            #expect(abs(sample.coordinate.longitude - 73.8) < 1e-9)
            #expect((18.5000...18.5012).contains(sample.coordinate.latitude))
        }
        let latitudes = samples.map(\.coordinate.latitude)
        #expect(latitudes == latitudes.sorted())   // always moving forward
    }

    @Test func timestampsComeFromTheInjectedClock() async {
        let clock = FakeClock()
        let begin = clock.now
        let samples = await collect(service([start, north], clock: clock).updates())
        #expect(samples.first?.timestamp == begin)
        #expect(samples.last?.timestamp == clock.now)
    }

    // MARK: Edge cases

    @Test func anEmptyRouteEmitsNothing() async {
        #expect(await collect(service([], clock: FakeClock()).updates()).isEmpty)
    }

    @Test func aRouteOfOnePointEmitsThatPointOnce() async {
        let samples = await collect(service([start], clock: FakeClock()).updates())
        #expect(samples.map(\.coordinate) == [start])
    }

    @Test func aZeroLengthRouteEmitsOnce() async {
        let samples = await collect(service([start, start], clock: FakeClock()).updates())
        #expect(samples.map(\.coordinate) == [start])
    }

    @Test func aZeroSpeedOrNegativeSpeedNeverMoves() async {
        #expect(await collect(service([start, north], speed: 0, clock: FakeClock()).updates()).isEmpty)
        #expect(await collect(service([start, north], speed: -1, clock: FakeClock()).updates()).isEmpty)
    }

    @Test func stoppingEarlyStopsTheWalk() async {
        let clock = FakeClock()
        var received = 0
        for await _ in service([start, north], clock: clock).updates() {
            received += 1
            if received == 5 { break }
        }
        #expect(received == 5)
    }

    @Test func cancellingTheListenerEndsTheStream() async {
        let clock = FakeClock()
        let task = Task { await collect(service([start, north], clock: clock).updates()) }
        task.cancel()
        let samples = await task.value
        #expect(samples.count < 95)
    }

    // MARK: Authorization

    @Test func theSimulationNeedsNoPermission() {
        let simulated = service([start, north], clock: FakeClock())
        #expect(simulated.authorization == .whenInUse && simulated.authorization.isAuthorized)
        simulated.requestWhenInUse()   // does nothing, and must not fail
    }

    @Test func onlyWhenInUseAndAlwaysAreAuthorized() {
        #expect(LocationAuthorization.whenInUse.isAuthorized && LocationAuthorization.always.isAuthorized)
        for blocked in [LocationAuthorization.notDetermined, .denied, .restricted] {
            #expect(!blocked.isAuthorized)
        }
    }

    // MARK: Samples and the live service

    @Test func samplesCompareByValue() {
        let one = LocationSample(coordinate: start, timestamp: Date(timeIntervalSince1970: 0), horizontalAccuracy: 5)
        let same = LocationSample(coordinate: start, timestamp: Date(timeIntervalSince1970: 0), horizontalAccuracy: 5)
        #expect(one == same)
        #expect(one != LocationSample(coordinate: north, timestamp: Date(timeIntervalSince1970: 0)))
    }

    /// The live service is not created or run in tests (no GPS, no prompt). This only proves, at compile time,
    /// that it keeps the same promise as the simulated one.
    @Test func theLiveServiceKeepsTheSamePromise() {
        let types: [any LocationService.Type] = [LiveLocationService.self, SimulatedLocationService.self]
        #expect(types.count == 2)
    }

    @Test func theRouteHelperMeasuresDistancesAndInterpolates() {
        let path = RoutePath([start, north])
        #expect(abs(path.length - 133.4) < 0.5)
        #expect(path.coordinate(at: 0) == start && path.coordinate(at: 9_999) == north)
        let middle = path.coordinate(at: path.length / 2)
        #expect(abs(middle.latitude - 18.5006) < 1e-6)
        #expect(RoutePath([]).isEmpty && RoutePath([]).length == 0)
    }
}
