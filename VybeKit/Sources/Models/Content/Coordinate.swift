import Foundation

/// Our own coordinate. Apple's `CLLocationCoordinate2D` is not `Codable` and would pull map code into Models.
public struct Coordinate: Codable, Hashable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
