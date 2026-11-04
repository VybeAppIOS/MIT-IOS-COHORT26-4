import Core
import Foundation
import Models

/// The person using the app, in `Application Support/Vybe/profile.json`. Before onboarding saves anything there is a
/// plain default profile. Other people do not exist in Phase 1 content, so they are `notFound`.
public struct LocalProfileRepository: ProfileRepository {
    private let file: DocumentFile<UserProfile>

    public init(file: DocumentFile<UserProfile>) {
        self.file = file
    }

    /// The normal file in Application Support.
    public init(now: @escaping @Sendable () -> Date = { Date() }) {
        let fallback = UserProfile(id: "user-local", username: "you", displayName: "You", createdAt: now())
        self.init(file: DocumentFile(url: LocalDataPaths.profileURL, empty: fallback, now: now))
    }

    public func currentProfile() async throws -> UserProfile { try await file.load() }

    public func profile(id: UserID) async throws -> UserProfile {
        let current = try await file.load()
        guard current.id == id else { throw AppError.notFound }
        return current
    }

    public func update(_ profile: UserProfile) async throws -> UserProfile {
        let current = try await file.load()
        guard profile.id == current.id else { throw AppError.notFound }
        try await file.save(profile)
        return profile
    }
}
