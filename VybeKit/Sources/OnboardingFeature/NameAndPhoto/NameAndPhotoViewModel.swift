import Core
import Foundation

/// O2: the person's name (required) and photo (optional). The name goes into the session's onboarding draft (in
/// memory, never UserDefaults). The photo is made safe by `PhotoProcessor` (resized, all metadata including the
/// location removed) and shown in the preview circle.
///
/// The processed photo stays in this ViewModel for now: nothing in Core can save a picked photo to a file yet, so
/// `onboardingDraft.photo` stays nil (Lohitaksh: a `savePhoto(ProcessedPhoto) async throws -> Photo` in Core,
/// implemented by LocalData, makes it one line in `continueTapped()`).
@MainActor @Observable
final class NameAndPhotoViewModel {
    /// 2 to 30 characters after trimming, counted as people see them (an emoji or a Devanagari letter is one).
    static let nameLength = 2...30

    /// What the person typed. Editing it allows the inline error to show.
    var name: String {
        didSet { hasEditedName = true }
    }
    private(set) var hasEditedName = false
    /// The small version of the processed photo, for the preview circle.
    private(set) var photoPreview: Data?
    /// Both sizes, kept until a save API exists (see the type's comment).
    private(set) var processedPhoto: ProcessedPhoto?
    private(set) var isProcessingPhoto = false
    /// Why the last photo could not be used; the person can try another or continue without one.
    private(set) var photoError: String?

    private let session: SessionStore
    private let router: Router
    private let processor: PhotoProcessor
    /// Counts picks, so a slow earlier photo never replaces a newer one.
    private var latestPick = 0

    /// Cheap: no loading here (ADR 005). Starts from any name already in the draft (coming back keeps it).
    init(session: SessionStore, router: Router, processor: PhotoProcessor) {
        self.session = session
        self.router = router
        self.processor = processor
        name = session.onboardingDraft.name    // property observers do not run in init: no error yet
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var isNameValid: Bool { Self.nameLength.contains(trimmedName.count) }

    /// Shown under the field only after the person has typed, never on an untouched empty field.
    var nameError: String? { hasEditedName && !isNameValid ? NameAndPhotoText.nameError : nil }

    var canContinue: Bool { isNameValid && !isProcessingPhoto }

    // MARK: Photo

    /// The View hands over the picked photo's bytes (PhotosUI stays in the View).
    func photoPicked(_ data: Data) async {
        latestPick += 1
        let pick = latestPick
        isProcessingPhoto = true
        photoError = nil
        defer { if pick == latestPick { isProcessingPhoto = false } }
        do {
            let processed = try await processor.process(data)
            guard pick == latestPick else { return }
            processedPhoto = processed
            photoPreview = processed.thumbnail
        } catch {
            guard pick == latestPick else { return }
            Log.onboarding.error("Profile photo not processed: \(error.localizedDescription, privacy: .public)")
            clearPhoto()
            photoError = NameAndPhotoText.photoError
        }
    }

    /// The picker could not hand over the photo at all (for example an iCloud photo that failed to download).
    func photoLoadFailed() {
        clearPhoto()
        photoError = NameAndPhotoText.photoError
    }

    func removePhoto() {
        latestPick += 1                         // ignore a photo that is still being processed
        isProcessingPhoto = false
        photoError = nil
        clearPhoto()
    }

    // MARK: Continue

    func continueTapped() {
        guard canContinue else { return }
        session.onboardingDraft.name = trimmedName
        router.open(.interests)
    }

    private func clearPhoto() {
        processedPhoto = nil
        photoPreview = nil
    }
}

/// O2's text, read from OnboardingFeature's own catalog (`bundle: #bundle`, task X-3).
enum NameAndPhotoText {
    static var title: String { String(localized: "onboarding.nameAndPhoto.title", bundle: #bundle) }
    static var namePlaceholder: String {
        String(localized: "onboarding.nameAndPhoto.namePlaceholder", bundle: #bundle)
    }
    static var nameError: String { String(localized: "onboarding.nameAndPhoto.nameError", bundle: #bundle) }
    static var addPhoto: String { String(localized: "onboarding.nameAndPhoto.addPhoto", bundle: #bundle) }
    static var changePhoto: String { String(localized: "onboarding.nameAndPhoto.changePhoto", bundle: #bundle) }
    static var removePhoto: String { String(localized: "onboarding.nameAndPhoto.removePhoto", bundle: #bundle) }
    static var photoOptional: String { String(localized: "onboarding.nameAndPhoto.photoOptional", bundle: #bundle) }
    static var photoError: String { String(localized: "onboarding.nameAndPhoto.photoError", bundle: #bundle) }
    static var processing: String { String(localized: "onboarding.nameAndPhoto.processing", bundle: #bundle) }
    static var continueButton: String { String(localized: "onboarding.nameAndPhoto.continue", bundle: #bundle) }
}
