import Core
import Testing
@testable import OnboardingFeature

@MainActor
struct InterestsViewModelTests {
    private func makeViewModel(_ deps: AppDependencies = .preview()) -> InterestsViewModel {
        InterestsViewModel(session: deps.session, router: deps.router)
    }

    // MARK: The minimum rule (task SC-O3)

    @Test func continueStaysDisabledUntilThreeAreChosen() {
        let viewModel = makeViewModel()
        #expect(!viewModel.canContinue)
        viewModel.toggle(.cafes)
        viewModel.toggle(.treks)
        #expect(!viewModel.canContinue)
        #expect(viewModel.progressText == "2 of 3 picked")
        viewModel.toggle(.sunsets)
        #expect(viewModel.canContinue)
        #expect(viewModel.progressText == nil)
        viewModel.toggle(.sunsets)                       // back to two
        #expect(!viewModel.canContinue)
    }

    @Test func continueUnderTheMinimumDoesNothing() {
        let deps = AppDependencies.preview()
        let viewModel = makeViewModel(deps)
        viewModel.toggle(.cafes)
        viewModel.continueTapped()
        #expect(deps.router.path(for: deps.router.currentStack).isEmpty)
    }

    @Test func continueOpensLocation() {
        let deps = AppDependencies.preview()
        deps.router.setOnboarding(true)
        let viewModel = makeViewModel(deps)
        [InterestOption.cafes, .treks, .gaming].forEach(viewModel.toggle)
        viewModel.continueTapped()
        #expect(deps.router.path(for: .onboarding) == [.location])
    }

    // MARK: Keeping the selection

    @Test func goingBackKeepsTheSelection() {
        let deps = AppDependencies.preview()
        let first = makeViewModel(deps)
        [InterestOption.cafes, .treks, .gaming].forEach(first.toggle)
        let returning = makeViewModel(deps)              // the screen is built again after going back
        #expect(returning.selected == [.cafes, .treks, .gaming])
        #expect(deps.session.onboardingDraft.interests == ["cafes", "treks", "gaming"])
    }

    @Test func tappingTwiceRemovesAnInterest() {
        let viewModel = makeViewModel()
        viewModel.toggle(.thrift)
        viewModel.toggle(.thrift)
        #expect(!viewModel.isSelected(.thrift))
    }

    // MARK: The list

    @Test func thereAreFourteenInterestsWithRealNames() {
        #expect(InterestOption.allCases.count == 14)
        #expect(Set(InterestOption.allCases.map(\.rawValue)).count == 14)
        #expect(InterestOption.streetFood.title == "Street food")
        #expect(InterestOption.allCases.allSatisfy { !$0.title.hasPrefix("onboarding.") })
    }
}
