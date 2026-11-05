#if DEBUG
import Core
import Models
import SwiftUI

extension ReportViewModel {
    /// The real ViewModel on the stub repositories, shown in one state.
    static func preview(
        _ mode: StubMode = .loaded, target: ReportTarget = .comment(CommentID("comment-example-kothrud")),
        selected: ReportReason? = nil, phase: Phase = .choosing, detail: String = ""
    ) -> ReportViewModel {
        let deps = AppDependencies.preview(mode)
        let viewModel = ReportViewModel(target: target, presentation: .sheet, safety: deps.safety, router: deps.router)
        viewModel.showForPreview(selected: selected, phase: phase, detail: detail)
        return viewModel
    }
}

#Preview("Choose a reason") { NavigationStack { ReportView(viewModel: .preview()) } }
#Preview("Reason chosen") { NavigationStack { ReportView(viewModel: .preview(selected: .spam)) } }
#Preview("Self-harm help") { NavigationStack { ReportView(viewModel: .preview(selected: .selfHarm)) } }
#Preview("Something else") {
    NavigationStack {
        ReportView(viewModel: .preview(selected: .other, detail: "This café is posting a stranger's number."))
    }
}
#Preview("Sending") { NavigationStack { ReportView(viewModel: .preview(selected: .harassment, phase: .sending)) } }
#Preview("Failed") { NavigationStack { ReportView(viewModel: .preview(selected: .scam, phase: .failed)) } }
#Preview("Thanks") {
    NavigationStack { ReportView(viewModel: .preview(selected: .spam, phase: .sent(hidden: false))) }
}
#Preview("Thanks, hidden") {
    NavigationStack { ReportView(viewModel: .preview(selected: .nudity, phase: .sent(hidden: true))) }
}
#Preview("Large text") {
    NavigationStack { ReportView(viewModel: .preview(selected: .selfHarm)) }
        .dynamicTypeSize(.accessibility3)
}
#endif
