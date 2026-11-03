# Template: a new screen (copy this, rename `Example`)

Reference implementation to copy: the first finished screen (`HangoutDetail`, task H-D1).
Until it exists, copy the patterns below. Full rules: `docs/ARCHITECTURE.md` 2.4, 2.5, 2.7.

Create, inside the right feature folder (for example `VybeKit/Sources/HangoutDetailFeature/Detail/`):

## `ExampleViewModel.swift`
```swift
import Core
import Models          // never SwiftUI in a ViewModel

public struct ExampleContent: Equatable, Sendable {   // view-ready values, never a raw model
    public let title: String
}

@MainActor @Observable
public final class ExampleViewModel {
    public private(set) var state: LoadState<ExampleContent> = .loading
    private let hangouts: any HangoutRepository
    private let router: Router
    private var hasLoaded = false

    public init(hangouts: any HangoutRepository, router: Router) {   // cheap: NO loading here
        self.hangouts = hangouts; self.router = router
    }

    public func load() async {
        guard !hasLoaded else { return }            // .task runs again when the screen reappears
        do {
            // let result = try await hangouts.hangout(id: ...)
            state = .loaded(ExampleContent(title: String(localized: "Example")))
            hasLoaded = true
        } catch { state = .failed(AppError(error)) }
    }

    public func somethingTapped() { /* router.open(...), a store call, ... */ }
}
```

## `ExampleView.swift`
```swift
import Design
import SwiftUI

public struct ExampleView: View {
    @State private var viewModel: ExampleViewModel
    public init(viewModel: ExampleViewModel) { _viewModel = State(initialValue: viewModel) }

    public var body: some View {
        LoadStateView(viewModel.state, onRetry: { Task { await viewModel.load() } }) { content in
            Text(content.title)                       // layout only; Theme tokens only
        }
        .task { await viewModel.load() }
    }
}
```

## `Example+Preview.swift` (wrap in `#if DEBUG`; uses the stubs from `Core/Fakes`)
```swift
#if DEBUG
extension ExampleViewModel {
    static func preview(_ mode: StubMode) -> ExampleViewModel { /* real ViewModel on Stub repositories */ }
}
#Preview("Loaded") { ExampleView(viewModel: .preview(.loaded)) }
#Preview("Empty") { ExampleView(viewModel: .preview(.empty)) }
#Preview("Error") { ExampleView(viewModel: .preview(.failed)) }
#Preview("Large text") { ExampleView(viewModel: .preview(.loaded)).dynamicTypeSize(.accessibility3) }
#endif
```

## `Tests/<Feature>Tests/ExampleViewModelTests.swift`
```swift
import Testing
@testable import ExampleFeature

@MainActor struct ExampleViewModelTests {
    @Test func loadsContent() async {
        let vm = ExampleViewModel.preview(.loaded)
        await vm.load()
        #expect(vm.state == .loaded(ExampleContent(title: "Example")))
    }
}
```

## Checklist before opening the PR
- [ ] View has no logic; ViewModel does not import SwiftUI; `init` is cheap; `load()` is idempotent
- [ ] Loading, empty and error states (and stale/offline from Phase 2) via `LoadStateView`
- [ ] Theme tokens only; accessibility labels; 44 pt tap targets; Dynamic Type preview
- [ ] Display text from `String(localized:)`; numbers, ₹, km and time through `.formatted(...)`
- [ ] Navigation only through `router` (never `router.cover = …`)
- [ ] `./scripts/check.sh` output and a simulator screenshot pasted in the PR
