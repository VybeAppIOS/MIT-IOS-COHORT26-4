#if DEBUG
import Foundation
import Models

/// Thrown by a contract check when an implementation breaks a repository promise.
public struct ContractFailure: Error, CustomStringConvertible {
    public let description: String

    public init(_ description: String) {
        self.description = description
    }
}

func require(_ condition: Bool, _ message: @autoclosure () -> String) throws {
    if !condition { throw ContractFailure(message()) }
}

/// Runs `body` and checks that it throws `AppError.notFound`.
func requireNotFound(_ what: String, _ body: () async throws -> Void) async throws {
    do {
        try await body()
        throw ContractFailure("\(what): expected AppError.notFound, got a value")
    } catch let error as AppError {
        try require(error == .notFound, "\(what): expected AppError.notFound, got \(error)")
    }
}

/// Runs `body` and checks that it throws `AppError.invalid` (a refused action, with a friendly reason).
func requireInvalid(_ body: () async throws -> Void) async throws {
    do {
        try await body()
    } catch let error as AppError {
        if case .invalid = error { return }
        throw ContractFailure("expected AppError.invalid, got \(error)")
    }
    throw ContractFailure("expected AppError.invalid, but the call succeeded")
}
#endif
