#if DEBUG
import Core
import Foundation
import Models

/// Debug builds run community, friends and chat on the sample social data (`SocialStubStore`), where "you" is
/// `SampleSocialData.currentUser`. The saved profile file has its own ID ("user-local"), so without this wrapper the
/// chat would not recognise your messages, comments or admin rights. Phase 2 (the backend) has one ID per person
/// and removes this file.
///
/// - `currentProfile()` keeps your saved name, photo and bio but answers with the sample ID.
/// - `profile(id:)` answers for your ID and for every sample person.
/// - `update(_:)` still saves to the local file, under the ID stored there.
struct SampleIdentityProfileRepository: ProfileRepository {
    private let local: any ProfileRepository
    private let sampleID: UserID

    init(wrapping local: any ProfileRepository, sampleID: UserID = SampleSocialData.currentUser.id) {
        self.local = local
        self.sampleID = sampleID
    }

    func currentProfile() async throws -> UserProfile {
        Self.copy(try await local.currentProfile(), id: sampleID)
    }

    func profile(id: UserID) async throws -> UserProfile {
        if id == sampleID { return try await currentProfile() }
        if let person = SampleSocialData.people.first(where: { $0.id == id }) { return person }
        return try await local.profile(id: id)
    }

    func update(_ profile: UserProfile) async throws -> UserProfile {
        guard profile.id == sampleID else { return try await local.update(profile) }
        let storedID = try await local.currentProfile().id
        let saved = try await local.update(Self.copy(profile, id: storedID))
        return Self.copy(saved, id: sampleID)
    }

    /// `UserProfile.id` is a `let`, so changing it means building a new profile.
    private static func copy(_ profile: UserProfile, id: UserID) -> UserProfile {
        UserProfile(
            id: id, username: profile.username, displayName: profile.displayName, photo: profile.photo,
            banner: profile.banner, bio: profile.bio, isPrivate: profile.isPrivate, interests: profile.interests,
            friendCount: profile.friendCount, settings: profile.settings, createdAt: profile.createdAt,
            deletedAt: profile.deletedAt)
    }
}
#endif
