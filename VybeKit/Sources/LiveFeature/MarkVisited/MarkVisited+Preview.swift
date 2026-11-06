#if DEBUG
import Core
import Design
import Models
import SwiftUI

extension MarkVisitedViewModel {
    /// The real ViewModel on a live run of the EXAMPLE Evening Hangout. `done` shows the success moment.
    static func preview(lastSpot: Bool = false, done: Bool = false) -> MarkVisitedViewModel {
        let deps = AppDependencies.preview()
        let spot = lastSpot ? SampleData.evening.spots[1] : SampleData.evening.spots[0]
        let name = lastSpot ? SampleData.park.name : SampleData.cafe.name
        let viewModel = MarkVisitedViewModel(
            spotID: spot.id, spotName: name, isLastSpot: lastSpot, liveStore: deps.liveStore,
            processor: PhotoProcessor(), sleep: { _ in try? await Task.sleep(for: .seconds(3_600)) }, onFinished: {})
        Task {
            _ = try? await deps.liveStore.startOrResume(hangoutID: SampleData.evening.id)
            if lastSpot { deps.liveStore.markVisited(spotID: SampleData.evening.spots[0].id) }
            if done { await viewModel.doneTapped() }
        }
        return viewModel
    }
}

/// The sheet over a plain background, the way it sits over the live screen.
private func sheet(_ viewModel: MarkVisitedViewModel) -> some View {
    Theme.Color.surface.ignoresSafeArea().sheet(isPresented: .constant(true)) {
        MarkVisitedView(viewModel: viewModel)
    }
}

#Preview("Mark visited?") { sheet(.preview()) }
#Preview("Visited") { sheet(.preview(done: true)) }
#Preview("Last Spot, confetti") { sheet(.preview(lastSpot: true, done: true)) }
#Preview("Reduce Motion: plain fade") {
    sheet(.preview(done: true)).environment(\.vybeReduceMotionOverride, true)
}
#Preview("Large text") { sheet(.preview()).dynamicTypeSize(.accessibility3) }
#endif
