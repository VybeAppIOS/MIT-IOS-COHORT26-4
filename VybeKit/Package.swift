// swift-tools-version: 6.2
// VybeKit: the local Swift package. Only Lohitaksh edits this file (see docs/ARCHITECTURE.md 3.1 and 3.2).
import PackageDescription

/// UI-side targets (Design, Components, Features) default to the main actor, like the app target.
/// Models, Core and LocalData do not (ADR 001).
let uiSettings: [SwiftSetting] = [
    .defaultIsolation(MainActor.self),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances")
]
let readme: [String] = ["README.md"]
let featureDeps: [Target.Dependency] = ["Models", "Core", "Design", "Components"]

let package = Package(
    name: "VybeKit",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Models", targets: ["Models"]),
        .library(name: "Core", targets: ["Core"]),
        .library(name: "Design", targets: ["Design"]),
        .library(name: "Components", targets: ["Components"]),
        .library(name: "LocalData", targets: ["LocalData"]),
        .library(name: "OnboardingFeature", targets: ["OnboardingFeature"]),
        .library(name: "DiscoverFeature", targets: ["DiscoverFeature"]),
        .library(name: "HangoutDetailFeature", targets: ["HangoutDetailFeature"]),
        .library(name: "LiveFeature", targets: ["LiveFeature"]),
        .library(name: "SearchFeature", targets: ["SearchFeature"]),
        .library(name: "ProfileFeature", targets: ["ProfileFeature"]),
        .library(name: "CommunityFeature", targets: ["CommunityFeature"]),
        .library(name: "EditorFeature", targets: ["EditorFeature"]),
        .library(name: "PostingFeature", targets: ["PostingFeature"]),
        .library(name: "FriendsFeature", targets: ["FriendsFeature"]),
        .library(name: "ChatFeature", targets: ["ChatFeature"]),
        .library(name: "AuthFeature", targets: ["AuthFeature"]),
        .library(name: "ModerationFeature", targets: ["ModerationFeature"])
    ],
    targets: [
        .target(name: "Models", exclude: readme, resources: [.process("Resources")]),
        // Core has no default isolation (ADR 001): only Router and the stores are @MainActor, written explicitly.
        .target(name: "Core", dependencies: ["Models"], exclude: readme),
        .target(name: "Design", dependencies: ["Models"], exclude: readme,
                resources: [.process("Resources")], swiftSettings: uiSettings),
        .target(name: "Components", dependencies: ["Models", "Design"], exclude: readme, swiftSettings: uiSettings),
        .target(name: "LocalData", dependencies: ["Core"], exclude: readme,
                resources: [.copy("Resources/Content")]),
        .target(name: "OnboardingFeature", dependencies: featureDeps, exclude: readme, swiftSettings: uiSettings),
        .target(name: "DiscoverFeature", dependencies: featureDeps, exclude: readme,
                resources: [.process("Resources")], swiftSettings: uiSettings),
        .target(name: "HangoutDetailFeature", dependencies: featureDeps, exclude: readme, swiftSettings: uiSettings),
        .target(name: "LiveFeature", dependencies: featureDeps, exclude: readme, swiftSettings: uiSettings),
        .target(name: "SearchFeature", dependencies: featureDeps, exclude: readme, swiftSettings: uiSettings),
        .target(name: "ProfileFeature", dependencies: featureDeps, exclude: readme, swiftSettings: uiSettings),
        .target(name: "CommunityFeature", dependencies: featureDeps, exclude: readme, swiftSettings: uiSettings),
        .target(name: "EditorFeature", dependencies: featureDeps, exclude: readme, swiftSettings: uiSettings),
        .target(name: "PostingFeature", dependencies: featureDeps, exclude: readme, swiftSettings: uiSettings),
        .target(name: "FriendsFeature", dependencies: featureDeps, exclude: readme, swiftSettings: uiSettings),
        .target(name: "ChatFeature", dependencies: featureDeps, exclude: readme, swiftSettings: uiSettings),
        .target(name: "AuthFeature", dependencies: featureDeps, exclude: readme, swiftSettings: uiSettings),
        .target(name: "ModerationFeature", dependencies: featureDeps, exclude: readme, swiftSettings: uiSettings),
        // Tests (Swift Testing). Test code that touches main-actor types is marked @MainActor.
        .testTarget(name: "ContentTests", dependencies: ["Models", "Core", "LocalData"]),
        .testTarget(name: "CoreTests", dependencies: ["Models", "Core"]),
        .testTarget(name: "LocalDataTests", dependencies: ["Models", "Core", "LocalData"],
                    resources: [.copy("Fixtures")]),
        .testTarget(name: "DesignTests", dependencies: ["Models", "Design"]),
        .testTarget(name: "ComponentsTests", dependencies: ["Models", "Design", "Components"]),
        .testTarget(name: "OnboardingFeatureTests", dependencies: ["OnboardingFeature", "Core"]),
        .testTarget(name: "DiscoverFeatureTests", dependencies: ["DiscoverFeature", "Core"]),
        .testTarget(name: "HangoutDetailFeatureTests", dependencies: ["HangoutDetailFeature", "Core"]),
        .testTarget(name: "LiveFeatureTests", dependencies: ["LiveFeature", "Core"]),
        .testTarget(name: "SearchFeatureTests", dependencies: ["SearchFeature", "Core"]),
        .testTarget(name: "ProfileFeatureTests", dependencies: ["ProfileFeature", "Core"]),
        .testTarget(name: "CommunityFeatureTests", dependencies: ["CommunityFeature", "Core"]),
        .testTarget(name: "EditorFeatureTests", dependencies: ["EditorFeature", "Core"]),
        .testTarget(name: "PostingFeatureTests", dependencies: ["PostingFeature", "Core"]),
        .testTarget(name: "FriendsFeatureTests", dependencies: ["FriendsFeature", "Core"]),
        .testTarget(name: "ChatFeatureTests", dependencies: ["ChatFeature", "Core"]),
        .testTarget(name: "AuthFeatureTests", dependencies: ["AuthFeature", "Core"]),
        .testTarget(name: "ModerationFeatureTests", dependencies: ["ModerationFeature", "Core"])
    ]
)
