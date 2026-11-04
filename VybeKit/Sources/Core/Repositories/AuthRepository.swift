import Foundation
import Models

/// Sign-in. Phase 1 builds the screens against stubs only; no real accounts or network calls yet.
public protocol AuthRepository: Sendable {
    func signInWithApple() async throws -> UserProfile
    func signInWithGoogle() async throws -> UserProfile
    func sendEmailCode(to email: String) async throws
    func verifyEmailCode(_ code: String, email: String) async throws -> UserProfile
    func isUsernameAvailable(_ username: String) async throws -> Bool
    /// The "account basics" step for a new person: unique username, date of birth, 18+ confirmation.
    func completeAccount(username: String, dateOfBirth: Date, confirmed18: Bool) async throws -> UserProfile
    func signOut() async throws
    func deleteAccount() async throws
}
