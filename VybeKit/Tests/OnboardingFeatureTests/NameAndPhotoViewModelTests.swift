import Core
import Foundation
import Testing
import UIKit
@testable import OnboardingFeature

@MainActor
struct NameAndPhotoViewModelTests {
    private func makeViewModel(_ deps: AppDependencies = .preview()) -> NameAndPhotoViewModel {
        NameAndPhotoViewModel(session: deps.session, router: deps.router, processor: PhotoProcessor())
    }

    /// A real small JPEG, drawn here (no real person's photo in tests).
    private func photoData() throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 400))
        let image = renderer.image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 600, height: 400))
        }
        return try #require(image.jpegData(compressionQuality: 0.8))
    }

    @Test(arguments: ["", "R", "   ", "  R  ", String(repeating: "a", count: 31)])
    func anInvalidNameKeepsContinueDisabled(name: String) {
        let viewModel = makeViewModel()
        viewModel.name = name
        #expect(!viewModel.canContinue)
    }

    @Test(arguments: ["Ri", "  Riya  ", String(repeating: "a", count: 30), "रिया"])
    func aValidNameAllowsContinue(name: String) {
        let viewModel = makeViewModel()
        viewModel.name = name
        #expect(viewModel.canContinue)
    }

    @Test func theErrorShowsOnlyAfterTyping() {
        let viewModel = makeViewModel()
        #expect(viewModel.nameError == nil)
        viewModel.name = "R"
        #expect(viewModel.nameError == NameAndPhotoText.nameError)
    }

    @Test func aPhotoThatCannotBeProcessedShowsAnErrorAndStillAllowsContinue() async {
        let deps = AppDependencies.preview()
        let viewModel = makeViewModel(deps)
        viewModel.name = "Riya"
        await viewModel.photoPicked(Data("not a photo".utf8))
        #expect(viewModel.photoError == NameAndPhotoText.photoError)
        #expect(viewModel.photoPreview == nil)
        #expect(viewModel.canContinue)
        viewModel.continueTapped()
        #expect(deps.router.path(for: deps.router.currentStack) == [.interests])
    }

    @Test func aRealPhotoIsProcessedIntoThePreview() async throws {
        let viewModel = makeViewModel()
        await viewModel.photoPicked(try photoData())
        #expect(viewModel.photoPreview != nil)
        #expect(viewModel.photoError == nil)
    }

    @Test func continueSavesTheTrimmedNameAndOpensInterests() {
        let deps = AppDependencies.preview()
        deps.router.setOnboarding(true)
        let viewModel = makeViewModel(deps)
        viewModel.name = "  Riya  "
        viewModel.continueTapped()
        #expect(deps.session.onboardingDraft.name == "Riya")
        #expect(deps.router.path(for: .onboarding) == [.interests])
    }

    @Test func comingBackKeepsTheNameFromTheDraft() {
        let deps = AppDependencies.preview()
        deps.session.onboardingDraft.name = "Riya"
        let viewModel = makeViewModel(deps)
        #expect(viewModel.name == "Riya")
        #expect(viewModel.nameError == nil)
    }

    @Test func textsResolveToRealText() {
        #expect(NameAndPhotoText.continueButton == "Continue")
        #expect(NameAndPhotoText.nameError == "Use 2 to 30 characters.")
    }
}
