import CoreLocation
import Foundation
import Models
import Synchronization

/// The real phone location, with Apple's modern API: `CLLocationUpdate.liveUpdates` for the positions and
/// `CLServiceSession` for the permission. No delegate callbacks at all, and never "Always".
///
/// While `updates()` is being listened to (a Hangout is live) it also holds a `CLBackgroundActivitySession`, so
/// updates continue with the screen off once the Location Background Mode is switched on in the project (task X-9).
/// Not used by tests: they use `SimulatedLocationService`.
public final class LiveLocationService: LocationService {
    private let session = Mutex<CLServiceSession?>(nil)

    public init() {}

    public var authorization: LocationAuthorization {
        switch CLLocationManager().authorizationStatus {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorizedWhenInUse: .whenInUse
        case .authorizedAlways: .always
        @unknown default: .denied
        }
    }

    /// Holding a "when in use" service session is what asks for the permission
    /// (it shows the system prompt the first time).
    public func requestWhenInUse() {
        session.withLock { held in
            if held == nil { held = CLServiceSession(authorization: .whenInUse) }
        }
    }

    public func updates() -> AsyncStream<LocationSample> {
        AsyncStream { continuation in
            let task = Task {
                let service = CLServiceSession(authorization: .whenInUse)
                let background = CLBackgroundActivitySession()
                defer {
                    background.invalidate()
                    service.invalidate()
                }
                do {
                    for try await update in CLLocationUpdate.liveUpdates(.fitness) {
                        guard let location = update.location else { continue }
                        continuation.yield(LocationSample(
                            coordinate: Coordinate(latitude: location.coordinate.latitude,
                                                   longitude: location.coordinate.longitude),
                            timestamp: location.timestamp,
                            horizontalAccuracy: location.horizontalAccuracy >= 0 ? location.horizontalAccuracy : nil))
                    }
                } catch {
                    // The updates ended (stopped or failed): the stream ends, and the screen shows its own state.
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
