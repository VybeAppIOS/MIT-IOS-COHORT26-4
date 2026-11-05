import Core
import Foundation
import Models

/// H2: "Mark <Spot> as visited?", an optional photo, and Done. Done marks the Spot in `LiveHangoutStore` (marking
/// twice changes nothing), shows the success moment (circle → checkmark, `.success` haptic; confetti once on the last
/// Spot, skipped with Reduce Motion), then closes the sheet.
///
/// Photos: up to 2 × visited Spots in the whole run (`HangoutRules.maxPhotos`, counting this Spot). A picked photo is
/// made safe by `PhotoProcessor` (resized, all metadata including location removed, RISKS 3). It is kept here and not
/// yet attached to the run: `liveStore.addPhoto` needs a saved `Photo`, and nothing in Core can save one yet
/// (Lohitaksh: the same `savePhoto(ProcessedPhoto) async throws -> Photo` asked for in SC-O2).
@MainActor @Observable
final class MarkVisitedViewModel {
    let spotID: SpotID
    let spotName: String
    /// This is the last Spot left: the success moment adds confetti.
    let isLastSpot: Bool

    private(set) var pickedPhotos: [ProcessedPhoto] = []
    private(set) var isProcessing = false
    private(set) var photoError: String?
    /// Marked: the sheet shows the success moment.
    private(set) var isDone = false

    private let liveStore: LiveHangoutStore
    private let processor: PhotoProcessor
    private let sleep: @Sendable (Duration) async -> Void
    private let onFinished: @MainActor () -> Void

    /// How long the success moment stays before the sheet closes.
    static let successPause = Duration.seconds(1.2)

    /// Cheap: no loading here (ADR 005). `sleep` is injected so tests do not wait.
    init(
        spotID: SpotID, spotName: String, isLastSpot: Bool, liveStore: LiveHangoutStore, processor: PhotoProcessor,
        sleep: @escaping @Sendable (Duration) async -> Void = { try? await Task.sleep(for: $0) },
        onFinished: @escaping @MainActor () -> Void
    ) {
        self.spotID = spotID
        self.spotName = spotName
        self.isLastSpot = isLastSpot
        self.liveStore = liveStore
        self.processor = processor
        self.sleep = sleep
        self.onFinished = onFinished
    }

    // MARK: Photos

    private var isAlreadyVisited: Bool { liveStore.run?.visits.contains { $0.spotID == spotID } ?? false }

    /// How many more photos fit: 2 × visited Spots (counting this one) minus the photos already in the run and
    /// the ones picked here.
    var photosLeft: Int {
        let visited = liveStore.visitedCount + (isAlreadyVisited ? 0 : 1)
        let inRun = liveStore.run?.photos.count ?? 0
        return max(0, HangoutRules.maxPhotos(visitedCount: visited) - inRun - pickedPhotos.count)
    }

    /// The most photos the run may hold once this Spot is visited ("up to 4 photos so far").
    var photoLimit: Int {
        HangoutRules.maxPhotos(visitedCount: liveStore.visitedCount + (isAlreadyVisited ? 0 : 1))
    }

    var canAddPhoto: Bool { photosLeft > 0 && !isProcessing && !isDone }

    /// The View hands over the picked photo's bytes (PhotosUI stays in the View).
    func photoPicked(_ data: Data) async {
        guard canAddPhoto else { return }
        isProcessing = true
        photoError = nil
        defer { isProcessing = false }
        do {
            pickedPhotos.append(try await processor.process(data))
        } catch is CancellationError {
            return
        } catch {
            photoError = MarkVisitedText.photoError
        }
    }

    func photoLoadFailed() { photoError = MarkVisitedText.photoError }

    func removePhoto(at index: Int) {
        guard pickedPhotos.indices.contains(index), !isDone else { return }
        pickedPhotos.remove(at: index)
    }

    // MARK: Done

    func doneTapped() async {
        guard !isDone else { return }           // marking twice changes nothing
        liveStore.markVisited(spotID: spotID)
        isDone = true
        await sleep(Self.successPause)
        onFinished()
    }

    /// Confetti only once, on the last Spot, and never with Reduce Motion (MOTION 3).
    func showsConfetti(reduceMotion: Bool) -> Bool { isDone && isLastSpot && !reduceMotion }
}

/// H2's text, read from LiveFeature's own catalog (`bundle: #bundle`, task X-3).
enum MarkVisitedText {
    static var addPhoto: String { String(localized: "live.markVisited.addPhoto", bundle: #bundle) }
    static var done: String { String(localized: "live.markVisited.done", bundle: #bundle) }
    static var visited: String { String(localized: "live.markVisited.visited", bundle: #bundle) }
    static var allVisited: String { String(localized: "live.markVisited.allVisited", bundle: #bundle) }
    static var photoError: String { String(localized: "live.markVisited.photoError", bundle: #bundle) }
    static var removePhoto: String { String(localized: "live.markVisited.removePhoto", bundle: #bundle) }

    /// "Mark EXAMPLE Café as visited?"
    static func question(_ name: String) -> String {
        String(localized: "live.markVisited.question \(name)", bundle: #bundle)
    }

    /// "You can add up to 4 photos so far."
    static func limitReached(_ limit: Int) -> String {
        String(localized: "live.markVisited.limitReached \(limit)", bundle: #bundle)
    }
}
