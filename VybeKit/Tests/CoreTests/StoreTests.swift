import Foundation
import Models
import Testing
@testable import Core

@MainActor
struct LibraryStoreTests {
    private let day = SampleData.day

    @Test func loadsThenTogglesSaveAndPersists() async throws {
        let repository = StubLibraryRepository(mode: .empty)
        let store = LibraryStore(repository: repository, now: { SampleData.day })
        await store.load()
        #expect(store.hasLoaded && store.savedHangoutIDs.isEmpty)

        await store.toggleSave(SampleData.evening.id)
        #expect(store.isSaved(SampleData.evening.id))
        #expect(try await repository.load().saves == [SavedHangout(hangoutID: SampleData.evening.id, savedAt: day)])

        await store.toggleSave(SampleData.evening.id)
        #expect(!store.isSaved(SampleData.evening.id))
        #expect(try await repository.load().saves.isEmpty)
    }

    @Test func aFailedSaveRollsBackAndReportsTheError() async {
        let store = LibraryStore(repository: FailingSaveLibrary(), now: { SampleData.day })
        await store.load()
        await store.toggleSave(SampleData.evening.id)
        #expect(!store.isSaved(SampleData.evening.id))
        #expect(store.lastError == .offline)
    }

    @Test func aFailedFirstLoadReportsTheError() async {
        let store = LibraryStore(repository: StubLibraryRepository(mode: .failing))
        await store.load()
        #expect(!store.hasLoaded && store.lastError == .offline)
    }

    @Test func draftsAreSavedReplacedAndDeleted() async {
        let store = LibraryStore(repository: StubLibraryRepository(mode: .empty))
        var draft = SampleData.morning
        draft.status = .draft
        await store.saveDraft(draft)
        draft.title = "EXAMPLE renamed"
        await store.saveDraft(draft)
        #expect(store.drafts.map(\.title) == ["EXAMPLE renamed"])
        await store.deleteDraft(draft.id)
        #expect(store.drafts.isEmpty)
    }

    @Test func savedListIsNewestFirst() async {
        var clock = SampleData.day
        let repository = StubLibraryRepository(mode: .empty)
        let store = LibraryStore(repository: repository, now: { [clock] in clock })
        await store.toggleSave(SampleData.evening.id)
        clock = clock.addingTimeInterval(60)
        let later = LibraryStore(repository: repository, now: { [clock] in clock })
        await later.load()
        await later.toggleSave(SampleData.morning.id)
        #expect(later.savedHangoutIDs == [SampleData.morning.id, SampleData.evening.id])
        _ = store
    }
}

@MainActor
struct SessionStoreTests {
    private func freshSettings() -> AppSettings { AppSettings(suiteName: "vybe.test.\(UUID().uuidString)") }

    @Test func completeOnboardingSavesTheDraft() {
        let settings = freshSettings()
        let session = SessionStore(settings: settings, currentUser: SampleData.signedInUser)
        #expect(!session.onboardingDone)
        session.onboardingDraft = OnboardingDraft(name: "Sample Renamed", interests: ["treks"], areaID: "kothrud")
        session.completeOnboarding()
        #expect(session.onboardingDone && settings.onboardingDone)
        #expect(settings.interests == ["treks"] && settings.selectedAreaID == "kothrud")
        #expect(session.currentUser?.displayName == "Sample Renamed")
        #expect(session.onboardingDraft == OnboardingDraft())
        #expect(SessionStore(settings: settings).onboardingDone)   // survives a restart
    }

    @Test func resetOnboardingClearsSettings() {
        let settings = freshSettings()
        let session = SessionStore(settings: settings)
        session.completeOnboarding()
        session.resetOnboarding()
        #expect(!session.onboardingDone && !settings.onboardingDone && settings.interests.isEmpty)
    }

    @Test func blockedPeopleAreKnown() {
        let session = SessionStore(settings: freshSettings(), blockedIDs: [SampleData.friend.id])
        #expect(session.isBlocked(SampleData.friend.id) && !session.isBlocked(SampleData.signedInUser.id))
    }
}

/// Loads fine, but every save fails.
private actor FailingSaveLibrary: LibraryRepository {
    func load() async throws -> Library { Library() }
    func save(_ library: Library) async throws { throw AppError.offline }
}
