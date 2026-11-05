#if DEBUG
import Core
import Foundation
import LocalData
import Models
import Testing
@testable import Vybe

/// While social data is stubbed, "you" must carry the sample person's ID but keep the saved name and photo.
struct SampleIdentityProfileRepositoryTests {
    private let sampleID = SampleSocialData.currentUser.id
    private let day = SampleData.day

    /// A repository over a throwaway file, so tests never touch the real profile.json.
    private func makeRepository(saved: UserProfile? = nil) async throws -> (SampleIdentityProfileRepository, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("profile-\(UUID().uuidString).json")
        let empty = UserProfile(id: "user-local", username: "you", displayName: "You", createdAt: day)
        let file = DocumentFile<UserProfile>(url: url, empty: empty, now: { SampleData.day })
        if let saved { try await file.save(saved) }
        return (SampleIdentityProfileRepository(wrapping: LocalProfileRepository(file: file)), url)
    }

    @Test func currentProfileKeepsTheSavedNameAndPhotoButUsesTheSampleID() async throws {
        let photo = Photo(id: "photo-1", path: "p.jpg", width: 10, height: 10)
        let saved = UserProfile(id: "user-local", username: "saved.name", displayName: "Saved Name", photo: photo,
                                bio: "A bio", createdAt: day)
        let (repository, url) = try await makeRepository(saved: saved)
        defer { try? FileManager.default.removeItem(at: url) }
        let current = try await repository.currentProfile()
        #expect(current.id == sampleID)
        #expect(current.displayName == "Saved Name" && current.username == "saved.name")
        #expect(current.photo == photo && current.bio == "A bio")
    }

    @Test func currentProfileWorksOnAFreshInstallToo() async throws {
        let (repository, url) = try await makeRepository()
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(try await repository.currentProfile().id == sampleID)
    }

    @Test func yourIDAnswersWithYourProfile() async throws {
        let saved = UserProfile(id: "user-local", username: "saved.name", displayName: "Saved Name", createdAt: day)
        let (repository, url) = try await makeRepository(saved: saved)
        defer { try? FileManager.default.removeItem(at: url) }
        let mine = try await repository.profile(id: sampleID)
        #expect(mine.id == sampleID && mine.displayName == "Saved Name")
    }

    @Test func everySamplePersonIsFoundAndStrangersAreNot() async throws {
        let (repository, url) = try await makeRepository()
        defer { try? FileManager.default.removeItem(at: url) }
        for person in SampleSocialData.people where person.id != sampleID {
            #expect(try await repository.profile(id: person.id) == person)
        }
        await #expect(throws: AppError.notFound) { try await repository.profile(id: "user-nobody") }
    }

    @Test func updateSavesUnderTheStoredIDAndAnswersWithTheSampleID() async throws {
        let (repository, url) = try await makeRepository()
        defer { try? FileManager.default.removeItem(at: url) }
        var mine = try await repository.currentProfile()
        mine.displayName = "New Name"
        let result = try await repository.update(mine)
        #expect(result.id == sampleID && result.displayName == "New Name")
        // A second repository over the same file sees the saved change, with the file's own ID.
        let reopened = LocalProfileRepository(file: DocumentFile(
            url: url, empty: UserProfile(id: "x", username: "x", displayName: "x", createdAt: day)))
        let stored = try await reopened.currentProfile()
        #expect(stored.id == "user-local" && stored.displayName == "New Name")
        #expect(try await repository.currentProfile().displayName == "New Name")
    }
}
#endif
