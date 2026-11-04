import Foundation

/// The errors a screen can show. Built from any `Error` with `init(_:)`; `message` is friendly text for people.
public enum AppError: Error, Equatable, Sendable {
    case notFound
    case offline
    /// The text is already friendly (for example "Add at least 2 Spots") and is shown as it is.
    case invalid(String)
    case unknown

    public init(_ error: any Error) {
        if let appError = error as? AppError {
            self = appError
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
                self = .offline
            default:
                self = .unknown
            }
        } else {
            self = .unknown
        }
    }

    public var message: String {
        switch self {
        case .notFound: String(localized: "error.notFound", bundle: #bundle)
        case .offline: String(localized: "error.offline", bundle: #bundle)
        case .invalid(let text): text
        case .unknown: String(localized: "error.unknown", bundle: #bundle)
        }
    }
}
