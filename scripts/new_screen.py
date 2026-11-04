#!/usr/bin/env python3
"""Creates a new screen from the template (task X-5, ADR 006): nobody starts a screen from a blank file.

  python3 scripts/new_screen.py <Feature> <Screen>        for example:  python3 scripts/new_screen.py Profile Saved

It writes, with your names (it never overwrites a file that exists):
  VybeKit/Sources/<Feature>Feature/<Screen>/<Screen>ViewModel.swift     the logic: LoadState, load(), reload()
  VybeKit/Sources/<Feature>Feature/<Screen>/<Screen>View.swift          the layout: LoadStateView, .task, .refreshable
  VybeKit/Sources/<Feature>Feature/<Screen>/<Screen>+Preview.swift      loaded / empty / error / large-text previews
  VybeKit/Tests/<Feature>FeatureTests/<Screen>ViewModelTests.swift      the ViewModel test every screen needs
and adds the screen's two words (title, empty text) to the feature's String Catalog.

Then it prints the one line you still change by hand: the placeholder `case` in <Feature>Screens.swift.
The generated code follows docs/templates/new-screen/README.md; once SC-HD1 (the golden screen) is merged, copy
its patterns into the ViewModel (the repository call, the content type) and keep this script in step with it.
Standard library only (AGENTS.md section 4).
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

VIEW_MODEL = '''import Core
import Models

/// The view-ready values of the {screen} screen (never a raw model).
struct {screen}Content: Equatable, Sendable {{
    let title: String
}}

/// {screen}: replace the placeholder load with the real repository call from your task.
@MainActor @Observable
final class {screen}ViewModel {{
    private(set) var state: LoadState<{screen}Content> = .loading
    private let hangouts: any HangoutRepository
    private let router: Router
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005). Take only what the screen needs, never `AppDependencies`.
    init(hangouts: any HangoutRepository, router: Router) {{
        self.hangouts = hangouts
        self.router = router
    }}

    /// Called by `.task`. Runs once; `.task` runs again whenever the screen reappears.
    func load() async {{
        guard !hasLoaded else {{ return }}
        await fetch()
    }}

    /// Pull to refresh and the Retry button.
    func reload() async {{ await fetch() }}

    var title: String {{ String(localized: "{key}.title", bundle: #bundle) }}
    var emptyMessage: String {{ String(localized: "{key}.empty", bundle: #bundle) }}

    private func fetch() async {{
        do {{
            _ = try await hangouts.picks()   // replace with the call your task needs
            state = .loaded({screen}Content(title: title))
            hasLoaded = true
        }} catch is CancellationError {{
            return   // leaving the screen is not an error (ADR 005)
        }} catch {{
            if case .loaded(let content, _) = state {{
                state = .loaded(content, isStale: true)   // a failed refresh keeps what is on screen
            }} else {{
                state = .failed(AppError(error))   // only a first load can fail
            }}
        }}
    }}
}}
'''

VIEW = '''import Design
import SwiftUI

/// Layout only: every value comes from `{screen}ViewModel`, every tap goes to it.
struct {screen}View: View {{
    @State private var viewModel: {screen}ViewModel

    init(viewModel: {screen}ViewModel) {{
        _viewModel = State(initialValue: viewModel)
    }}

    var body: some View {{
        LoadStateView(viewModel.state, onRetry: {{ Task {{ await viewModel.reload() }} }}) {{ content in
            ScrollView {{
                Text(verbatim: content.title)
                    .font(Theme.Font.title2)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.large)
                    .accessibilityIdentifier("{key}.title")
            }}
        }} placeholder: {{
            Text(verbatim: "Placeholder title")
                .font(Theme.Font.title2)
                .padding(Theme.Spacing.large)
        }} empty: {{
            EmptyStateView(systemImage: "sparkles", message: viewModel.emptyMessage)
        }}
        .navigationTitle(Text(verbatim: viewModel.title))
        .background(Theme.Color.surface)
        .task {{ await viewModel.load() }}
        .refreshable {{ await viewModel.reload() }}
    }}
}}
'''

PREVIEW = '''#if DEBUG
import Core
import SwiftUI

extension {screen}ViewModel {{
    /// The real ViewModel on the stub repositories, in one state.
    static func preview(_ mode: StubMode) -> {screen}ViewModel {{
        let deps = AppDependencies.preview(mode)
        return {screen}ViewModel(hangouts: deps.hangouts, router: deps.router)
    }}
}}

#Preview("Loaded") {{ NavigationStack {{ {screen}View(viewModel: .preview(.loaded)) }} }}
#Preview("Empty") {{ NavigationStack {{ {screen}View(viewModel: .preview(.empty)) }} }}
#Preview("Error") {{ NavigationStack {{ {screen}View(viewModel: .preview(.failing)) }} }}
#Preview("Loading") {{ NavigationStack {{ {screen}View(viewModel: .preview(.neverReturns)) }} }}
#Preview("Large text") {{
    NavigationStack {{ {screen}View(viewModel: .preview(.loaded)) }}
        .dynamicTypeSize(.accessibility3)
}}
#endif
'''

TEST = '''import Core
import Models
import Testing
@testable import {feature}Feature

@MainActor
struct {screen}ViewModelTests {{
    @Test func loadShowsContent() async {{
        let viewModel = {screen}ViewModel.preview(.loaded)
        await viewModel.load()
        guard case .loaded = viewModel.state else {{
            Issue.record("expected loaded, got \\(viewModel.state)")
            return
        }}
    }}

    @Test func aFailedFirstLoadShowsTheError() async {{
        let viewModel = {screen}ViewModel.preview(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }}
}}
'''


def fail(message):
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def words(name):
    """'HangoutDetail' -> 'Hangout detail' (the first English value for the catalog)."""
    spaced = re.sub(r'(?<!^)(?=[A-Z])', ' ', name)
    return spaced[:1].upper() + spaced[1:].lower()


def main():
    if len(sys.argv) != 3:
        fail("usage: python3 scripts/new_screen.py <Feature> <Screen>   (for example: Profile Saved)")
    feature = sys.argv[1].removesuffix("Feature")
    screen = sys.argv[2].removesuffix("View")
    for value, what in ((feature, "Feature"), (screen, "Screen")):
        if not re.fullmatch(r'[A-Z][A-Za-z0-9]*', value):
            fail(f"{what} must be UpperCamelCase letters and digits, got '{value}'")

    sources = os.path.join(ROOT, "VybeKit/Sources", f"{feature}Feature")
    tests = os.path.join(ROOT, "VybeKit/Tests", f"{feature}FeatureTests")
    if not os.path.isdir(sources):
        known = sorted(d.removesuffix("Feature") for d in os.listdir(os.path.join(ROOT, "VybeKit/Sources"))
                       if d.endswith("Feature"))
        fail(f"no feature '{feature}'. Known: {', '.join(known)}")

    key = f"{feature[:1].lower()}{feature[1:]}.{screen[:1].lower()}{screen[1:]}"
    values = {"screen": screen, "feature": feature, "key": key}
    files = {
        os.path.join(sources, screen, f"{screen}ViewModel.swift"): VIEW_MODEL,
        os.path.join(sources, screen, f"{screen}View.swift"): VIEW,
        os.path.join(sources, screen, f"{screen}+Preview.swift"): PREVIEW,
        os.path.join(tests, f"{screen}ViewModelTests.swift"): TEST,
    }
    existing = [path for path in files if os.path.exists(path)]
    if existing:
        fail("these files exist already (nothing was written):\n  " + "\n  ".join(existing))

    for path, template in files.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(template.format(**values))
        print(f"created {os.path.relpath(path, ROOT)}")

    catalog_path = os.path.join(sources, "Resources", "Localizable.xcstrings")
    if os.path.exists(catalog_path):
        with open(catalog_path, encoding="utf-8") as handle:
            catalog = json.load(handle)
        entries = {
            f"{key}.title": (words(screen), f"Title of the {words(screen)} screen."),
            f"{key}.empty": ("Nothing here yet.", f"Empty state of the {words(screen)} screen. Write it in our tone."),
        }
        for entry, (value, comment) in entries.items():
            catalog["strings"].setdefault(entry, {
                "comment": comment,
                "localizations": {"en": {"stringUnit": {"state": "translated", "value": value}}},
            })
        with open(catalog_path, "w", encoding="utf-8") as handle:
            handle.write(json.dumps(catalog, indent=2, ensure_ascii=False, sort_keys=True,
                                    separators=(",", " : ")) + "\n")
        print(f"added {key}.title and {key}.empty to {os.path.relpath(catalog_path, ROOT)}")

    print(f"""
Next, by hand (one line): in VybeKit/Sources/{feature}Feature/{feature}Screens.swift replace your screen's placeholder
with
    {screen}View(viewModel: {screen}ViewModel(hangouts: deps.hangouts, router: deps.router))
Then: replace the placeholder load in {screen}ViewModel.fetch() with the call your task needs, build the layout in
{screen}View, look at the previews, run ./scripts/check.sh.""")


if __name__ == "__main__":
    main()
