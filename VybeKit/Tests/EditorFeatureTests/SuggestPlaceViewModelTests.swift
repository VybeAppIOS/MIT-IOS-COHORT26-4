import Core
import Foundation
import Models
import Testing
@testable import EditorFeature

@MainActor
struct SuggestPlaceViewModelTests {
    /// Remembers what was sent.
    private final class Outbox {
        var sent: [PlaceSuggestion] = []
    }

    private func make(
        _ presentation: SuggestPlacePresentation = .sheet, failing: Bool = false, outbox: Outbox = Outbox()
    ) -> (SuggestPlaceViewModel, AppDependencies) {
        let deps = AppDependencies.preview()
        let viewModel = SuggestPlaceViewModel(
            presentation: presentation, session: deps.session, router: deps.router,
            processPhoto: { data in
                guard !data.isEmpty else { throw PhotoProcessingError.notAnImage }
                return ProcessedPhoto(large: data, thumbnail: data)
            },
            submit: { suggestion in
                if failing { throw AppError.offline }
                outbox.sent.append(suggestion)
            },
            now: { SampleData.day }, makeID: { "id1" })
        return (viewModel, deps)
    }

    @Test func aPhotoIsRequired() async {
        let outbox = Outbox()
        let (viewModel, _) = make(outbox: outbox)
        viewModel.name = "EXAMPLE Tapri"
        await viewModel.sendTapped()
        #expect(viewModel.photoMissing != nil && outbox.sent.isEmpty && !viewModel.isSent)
    }

    @Test(arguments: [("", false), ("A", false), ("Ab", true), (String(repeating: "a", count: 60), true),
                      (String(repeating: "a", count: 61), false)])
    func nameLength(name: String, valid: Bool) async {
        let (viewModel, _) = make()
        viewModel.name = name
        await viewModel.sendTapped()
        #expect((viewModel.nameError == nil) == valid)
    }

    @Test func noErrorsShowBeforeTheFirstTry() {
        let (viewModel, _) = make()
        #expect(viewModel.nameError == nil && viewModel.photoMissing == nil)
    }

    @Test func aValidSuggestionIsSentAsPendingWithTheMapCentre() async {
        let outbox = Outbox()
        let (viewModel, _) = make(outbox: outbox)
        await viewModel.photoPicked(Data([1, 2, 3]))
        viewModel.name = "  EXAMPLE Tapri  "
        viewModel.category = .chaiTapri
        viewModel.centre = Coordinate(latitude: 18.51, longitude: 73.81)
        await viewModel.sendTapped()
        #expect(viewModel.isSent)
        let sent = outbox.sent.first
        #expect(sent?.name == "EXAMPLE Tapri" && sent?.status == .pending && sent?.category == .chaiTapri)
        #expect(sent?.coordinate == Coordinate(latitude: 18.51, longitude: 73.81))
        #expect(sent?.submitterID == SampleData.signedInUser.id && sent?.id == "suggestion-id1")
    }

    @Test func aPhotoThatCannotBeReadShowsAWarning() async {
        let (viewModel, _) = make()
        await viewModel.photoPicked(Data())
        #expect(viewModel.photoFailed && viewModel.photo == nil)
    }

    @Test func aFailedSendKeepsTheForm() async {
        let (viewModel, _) = make(failing: true)
        await viewModel.photoPicked(Data([1, 2, 3]))
        viewModel.name = "EXAMPLE Tapri"
        await viewModel.sendTapped()
        #expect(viewModel.hasFailed && viewModel.name == "EXAMPLE Tapri")
    }

    @Test func closingFollowsHowItWasOpened() {
        let (sheet, sheetDeps) = make(.sheet)
        sheetDeps.router.present(.suggestPlace)
        sheet.closeTapped()
        #expect(sheetDeps.router.sheet == nil)

        let (pushed, pushedDeps) = make(.pushed)
        pushedDeps.router.present(.spot("p1"))
        pushedDeps.router.open(.suggestPlace)
        pushed.closeTapped()
        #expect(pushedDeps.router.path(for: .sheet).isEmpty && pushedDeps.router.sheet != nil)
    }
}
