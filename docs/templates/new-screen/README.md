# Template: a new screen (copy this, rename `Example`)

Reference implementation to copy: the first finished screen (`HangoutDetail`, task SC-HD1). Once task X-5 exists, run
`scripts/new_screen.py <Feature> <Screen>` instead of copying by hand. Until SC-HD1 exists, copy the patterns below.
Rules: `docs/ARCHITECTURE.md` 2.4, 2.5, 2.7 and the ADRs in `docs/adr/` (they win where they differ). The code below is
**unverified** until F-0 compiles it.

Create, inside the right feature folder (for example `VybeKit/Sources/HangoutDetailFeature/Detail/`). **Everything is
`internal`.** The feature's only `public` type is its `<Name>Screens` (ADR 002).

## Strings (task X-3)
Each target that shows text owns `Resources/Localizable.xcstrings` (it needs `resources: [.process("Resources")]` in its
`Package.swift` target; ask Lohitaksh). Always write `String(localized: "feature.key", bundle: #bundle)`: without
`bundle:` Swift reads the app's catalog and the string silently stays as the key. Keys are `<feature>.<name>`. A word used
by several features goes in `Design/Resources/Localizable.xcstrings` and is exposed as a value in `Design/Strings/SharedStrings.swift`
(a feature cannot read another target's catalog by key). Test it: `#expect(MyStrings.title == "...")`.
Never write `#bundle` in a test file: there it points at the test bundle, not your target. Test through your
target's own accessor, as above.

## `ExampleViewModel.swift`
```swift
import Core
import Models          // never SwiftUI in a ViewModel

struct ExampleContent: Equatable, Sendable {     // view-ready values, never a raw model
    let title: String
}

@MainActor @Observable
final class ExampleViewModel {
    private(set) var state: LoadState<ExampleContent> = .loading
    private let hangouts: any HangoutRepository
    private let router: Router
    private var hasLoaded = false

    init(hangouts: any HangoutRepository, router: Router) {      // cheap: NO loading here
        self.hangouts = hangouts; self.router = router
    }

    func load() async {                                          // called by .task
        guard !hasLoaded else { return }                         // .task runs again when the screen reappears
        await fetch()
    }
    func reload() async { await fetch() }                        // pull to refresh and the Retry button

    private func fetch() async {
        do {
            // let result = try await hangouts.hangout(id: ...)
            state = .loaded(ExampleContent(title: String(localized: "example.title", bundle: #bundle)))
            hasLoaded = true
        } catch is CancellationError {
            return                                               // leaving the screen is not an error (ADR 005)
        } catch {
            if case .loaded(let content, _) = state {
                state = .loaded(content, isStale: true)          // a failed refresh keeps what is on screen
            } else {
                state = .failed(AppError(error))                 // only a first load can fail
            }
        }
    }

    func somethingTapped() { /* router.open(...), a store call, ... */ }
}
```

## `ExampleView.swift`
```swift
import Design
import SwiftUI

struct ExampleView: View {
    @State private var viewModel: ExampleViewModel
    init(viewModel: ExampleViewModel) { _viewModel = State(initialValue: viewModel) }

    var body: some View {
        LoadStateView(viewModel.state, onRetry: { Task { await viewModel.reload() } }) { content in
            Text(content.title)                       // layout only; Theme tokens only
                .accessibilityIdentifier("example.title")   // <screen>.<element>, used by UI tests and snapshots
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
    }
}
```

## `ExampleScreens.swift` (the feature's ONE public type; already created by F-16, you add your `case`)
```swift
import Core
import SwiftUI

public enum ExampleScreens {
    @ViewBuilder
    public static func view(for route: ExampleRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .detail(let id):
            ExampleView(viewModel: ExampleViewModel(hangouts: deps.hangouts, router: deps.router))
        }
    }
}
```
The ViewModel's `init` takes only what it needs, never `AppDependencies`.

## `Example+Preview.swift` (wrap in `#if DEBUG`; builds the **real** ViewModel on the stubs)
```swift
#if DEBUG
extension ExampleViewModel {
    static func preview(_ mode: StubMode) -> ExampleViewModel {
        let deps = AppDependencies.preview(mode)
        return ExampleViewModel(hangouts: deps.hangouts, router: deps.router)
    }
}
#Preview("Loaded") { ExampleView(viewModel: .preview(.loaded)) }
#Preview("Empty") { ExampleView(viewModel: .preview(.empty)) }
#Preview("Error") { ExampleView(viewModel: .preview(.failing)) }
#Preview("Large text") { ExampleView(viewModel: .preview(.loaded)).dynamicTypeSize(.accessibility3) }
#endif
```

## `Tests/<Feature>Tests/ExampleViewModelTests.swift`
```swift
import Testing
@testable import ExampleFeature          // @testable gives access to the internal types

@MainActor struct ExampleViewModelTests {
    @Test func loadsContent() async {
        let vm = ExampleViewModel.preview(.loaded)
        await vm.load()
        #expect(vm.state == .loaded(ExampleContent(title: "Example")))
    }
    @Test func failedRefreshKeepsContent() async { /* load, make the stub fail, reload, expect .loaded(_, isStale: true) */ }
}
```

## Checklist before opening the PR
- [ ] Only your screen's folder, your `case` in `<Name>Screens.swift` and your tests changed (no App, Models, Core/Navigation, Theme, Package)
- [ ] View has no logic; ViewModel does not import SwiftUI; `init` is cheap; `load()` is idempotent; `reload()` exists
- [ ] Cancellation does not change `state`; a failed refresh keeps the content
- [ ] Loading, empty and error states (and stale/offline from Phase 2) via `LoadStateView`
- [ ] Theme tokens only; accessibility labels and identifiers; 44 pt tap targets; Dynamic Type preview
- [ ] Display text from `String(localized: "feature.key", bundle: #bundle)` (Views: `Text("feature.key", bundle: #bundle)`), added to your target's own catalog; numbers, ₹, km and time through `.formatted(...)`
- [ ] Navigation only through `router` methods (never `router.cover = …`)
- [ ] Nothing invented: places, prices, hours, coordinates and photos come from the repositories or the real samples
- [ ] `./scripts/check.sh` output, and a screenshot per state (`scripts/snap.sh` once X-14 exists), pasted in the PR
