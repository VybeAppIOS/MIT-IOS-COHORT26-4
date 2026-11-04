import Foundation
import Models

public protocol ProfileRepository: Sendable {
    /// The person using the app.
    func currentProfile() async throws -> UserProfile
    func profile(id: UserID) async throws -> UserProfile
    /// Saves changes to the current person's profile and returns what was stored.
    func update(_ profile: UserProfile) async throws -> UserProfile
}
