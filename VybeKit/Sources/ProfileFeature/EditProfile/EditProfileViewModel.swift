import Core
import Foundation
import Models

/// One interest chip: the stored word and the words shown.
struct InterestOption: Identifiable, Equatable {
    let id: String
    let title: String
}

/// PR6, Edit profile (a sheet from My profile and Settings). Name, username, photo, banner, bio and at least three
/// interests. Save stays disabled until everything is valid; closing with changes asks first.
@MainActor @Observable
final class EditProfileViewModel {
    enum Phase: Equatable {
        case editing
        case saving
        /// The save did not go through; every field keeps what was typed.
        case failed
        /// Saved: the sheet closes.
        case saved
    }

    static let bioLimit = 150
    static let nameLimit = 40
    static let minimumInterests = 3

    var name: String
    var username: String
    var bio: String
    private(set) var interests: Set<String>
    private(set) var phase: Phase = .editing
    /// The chosen username is taken (checked when saving).
    private(set) var usernameTaken = false
    /// A new photo or banner was picked and made safe (resized, location removed) by `PhotoProcessor`.
    private(set) var newPhoto: ProcessedPhoto?
    private(set) var newBanner: ProcessedPhoto?
    private(set) var photoFailed = false
    /// "Discard changes?" is up.
    var isConfirmingDiscard = false

    private let original: UserProfile
    private let profiles: any ProfileRepository
    private let auth: any AuthRepository
    private let session: SessionStore
    private let processor: PhotoProcessor

    /// Cheap: the form starts from the profile the caller already has (ADR 005).
    init(
        profile: UserProfile, profiles: any ProfileRepository, auth: any AuthRepository, session: SessionStore,
        processor: PhotoProcessor = PhotoProcessor()
    ) {
        original = profile
        name = profile.displayName
        username = profile.username
        bio = profile.bio ?? ""
        interests = Set(profile.interests)
        self.profiles = profiles
        self.auth = auth
        self.session = session
        self.processor = processor
    }

    // MARK: Words

    var title: String { String(localized: "profile.edit.title", bundle: #bundle) }
    var nameLabel: String { String(localized: "profile.edit.name", bundle: #bundle) }
    var usernameLabel: String { String(localized: "profile.edit.username", bundle: #bundle) }
    var bioLabel: String { String(localized: "profile.edit.bio", bundle: #bundle) }
    var interestsLabel: String { String(localized: "profile.edit.interests", bundle: #bundle) }
    var photoLabel: String { String(localized: "profile.edit.photo", bundle: #bundle) }
    var bannerLabel: String { String(localized: "profile.edit.banner", bundle: #bundle) }
    var photoReady: String { String(localized: "profile.edit.photo.ready", bundle: #bundle) }
    var photoError: String { String(localized: "profile.edit.photo.error", bundle: #bundle) }
    var saveTitle: String { String(localized: "profile.edit.save", bundle: #bundle) }
    var errorMessage: String { String(localized: "profile.edit.error", bundle: #bundle) }
    var discardTitle: String { String(localized: "profile.edit.discard", bundle: #bundle) }
    var discardConfirm: String { String(localized: "profile.edit.discard.confirm", bundle: #bundle) }
    var keepEditing: String { String(localized: "profile.edit.keep", bundle: #bundle) }

    var bioCountText: String { "\(bio.count)/\(Self.bioLimit)" }
    var interestsCountText: String {
        String(format: String(localized: "profile.edit.interests.count", bundle: #bundle), interests.count,
               Self.minimumInterests)
    }

    /// The 30-day hold, shown only when the username is being changed (the old one is held, then freed).
    var usernameHoldNote: String? {
        normalizedUsername == original.username ? nil : String(localized: "profile.edit.username.hold", bundle: #bundle)
    }

    let interestOptions: [InterestOption] = EditProfileViewModel.interestKeys.map { key in
        // A plain key built from the stored word (not an interpolated format key).
        let resource = String.LocalizationValue(stringLiteral: "profile.interest." + key)
        return InterestOption(id: key, title: String(localized: resource, bundle: #bundle))
    }

    /// The interests people can pick. Stored as these words in `UserProfile.interests`.
    static let interestKeys = ["cafes", "street-food", "treks", "forts", "parks", "gaming", "live-music",
                               "museums", "art", "markets", "sports", "study-spots"]

    // MARK: Validation

    var normalizedUsername: String { username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

    var nameError: String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return String(localized: "profile.edit.name.empty", bundle: #bundle) }
        if trimmed.count > Self.nameLimit { return String(localized: "profile.edit.name.long", bundle: #bundle) }
        return nil
    }

    var usernameError: String? {
        if usernameTaken { return String(localized: "profile.edit.username.taken", bundle: #bundle) }
        return Self.usernameProblem(normalizedUsername)
    }

    var bioError: String? {
        bio.count > Self.bioLimit ? String(localized: "profile.edit.bio.long", bundle: #bundle) : nil
    }

    var interestsError: String? {
        interests.count < Self.minimumInterests
            ? String(localized: "profile.edit.interests.few", bundle: #bundle) : nil
    }

    /// Like big apps: 3 to 30 characters; lower-case letters, numbers, dots and underscores; no dot at either end
    /// and never two dots in a row.
    static func usernameProblem(_ value: String) -> String? {
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789._")
        guard (3...30).contains(value.count) else {
            return String(localized: "profile.edit.username.length", bundle: #bundle)
        }
        guard value.allSatisfy({ allowed.contains($0) }), !value.hasPrefix("."), !value.hasSuffix("."),
              !value.contains("..") else {
            return String(localized: "profile.edit.username.characters", bundle: #bundle)
        }
        return nil
    }

    var hasChanges: Bool {
        name != original.displayName || normalizedUsername != original.username || bio != (original.bio ?? "")
            || interests != Set(original.interests) || newPhoto != nil || newBanner != nil
    }

    var isValid: Bool {
        nameError == nil && Self.usernameProblem(normalizedUsername) == nil && bioError == nil && interestsError == nil
    }

    var canSave: Bool { isValid && hasChanges && phase != .saving }
    var isSaving: Bool { phase == .saving }
    var hasFailed: Bool { phase == .failed }
    var isSaved: Bool { phase == .saved }

    // MARK: What the person does

    func isSelected(_ option: InterestOption) -> Bool { interests.contains(option.id) }

    func toggleInterest(_ option: InterestOption) {
        if interests.contains(option.id) { interests.remove(option.id) } else { interests.insert(option.id) }
    }

    /// A new username clears the "taken" message until the next save checks again.
    func usernameEdited() { usernameTaken = false }

    /// Picked photo data is resized and stripped of location before anything keeps it (`docs/RISKS.md` 3).
    func photoPicked(_ data: Data, isBanner: Bool) async {
        do {
            let processed = try await processor.process(data)
            if isBanner { newBanner = processed } else { newPhoto = processed }
            photoFailed = false
        } catch {
            photoFailed = true
        }
    }

    func save() async {
        guard canSave else { return }
        phase = .saving
        do {
            if normalizedUsername != original.username {
                let available = try await auth.isUsernameAvailable(normalizedUsername)
                guard available else {
                    usernameTaken = true
                    phase = .editing
                    return
                }
            }
            var changed = original
            changed.displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            changed.username = normalizedUsername
            let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
            changed.bio = trimmedBio.isEmpty ? nil : trimmedBio
            changed.interests = Self.interestKeys.filter { interests.contains($0) }
            let saved = try await profiles.update(changed)
            session.setCurrentUser(saved)
            phase = .saved
        } catch is CancellationError {
            phase = .editing   // leaving the screen is not an error (ADR 005)
        } catch {
            phase = .failed
        }
    }

    /// Close: straight away when nothing changed, otherwise ask first.
    func closeTapped() -> Bool {
        if hasChanges {
            isConfirmingDiscard = true
            return false
        }
        return true
    }
}
