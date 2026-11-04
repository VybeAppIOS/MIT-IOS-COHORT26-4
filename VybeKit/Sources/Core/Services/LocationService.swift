import Foundation
import Models

/// One place and time from the phone.
public struct LocationSample: Sendable, Equatable {
    public var coordinate: Coordinate
    public var timestamp: Date
    /// How sure the phone is, in metres (smaller is better). Nil when unknown.
    public var horizontalAccuracy: Double?

    public init(coordinate: Coordinate, timestamp: Date, horizontalAccuracy: Double? = nil) {
        self.coordinate = coordinate
        self.timestamp = timestamp
        self.horizontalAccuracy = horizontalAccuracy
    }
}

public enum LocationAuthorization: Sendable, Equatable {
    case notDetermined
    case denied
    case restricted
    case whenInUse
    /// The app never asks for this (`AGENTS.md` 5a); it can only come from the person's own Settings.
    case always

    /// Whether location updates can flow.
    public var isAuthorized: Bool { self == .whenInUse || self == .always }
}

/// Where the phone is. The only way the app reads location (`AGENTS.md` 5a): the live Hangout screen and the
/// onboarding location step use it, so a desk demo can swap in `SimulatedLocationService`.
public protocol LocationService: Sendable {
    var authorization: LocationAuthorization { get }
    /// Starts location updates. They stop when the caller stops listening (the loop ends or its task is cancelled).
    func updates() -> AsyncStream<LocationSample>
    /// Asks for "While Using the App". Never "Always".
    func requestWhenInUse()
}
