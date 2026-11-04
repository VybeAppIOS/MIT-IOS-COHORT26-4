# Vybe: Sources

Evidence links for the decisions in the other documents, kept here so those stay short. Each section matches one document.
"Checked" in a document means the claim was read on the original source; most other links are blogs or forums, so check the
official page before relying on them. None of this is legal advice.

## Architecture (`docs/ARCHITECTURE.md`)

Open-source apps: [Ice Cubes](https://github.com/Dimillian/IceCubesApp) ·
[Router](https://github.com/Dimillian/IceCubesApp/blob/main/Packages/Env/Sources/Env/Router.swift) ·
[Route → screen map](https://github.com/Dimillian/IceCubesApp/blob/main/IceCubesApp/App/Router/AppRegistry.swift) ·
[router tests](https://github.com/Dimillian/IceCubesApp/blob/main/Packages/Env/Tests/RouterTests.swift) ·
[IcySky](https://github.com/Dimillian/IcySky) · [Element X](https://github.com/element-hq/element-x-ios) ·
[Damus router](https://github.com/damus-io/damus/blob/master/damus/Shared/Utilities/Router.swift) ·
[Damus per-tab stacks](https://github.com/damus-io/damus/commit/204c325) ·
[Backyard Birds](https://github.com/apple/sample-backyard-birds/blob/main/Multiplatform/Backyards/BackyardNavigationStack.swift) ·
[Food Truck](https://github.com/apple/sample-food-truck) ·
[Landmarks](https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass) ·
[isowords](https://github.com/pointfreeco/isowords)

Apple: [Managing model data](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app) ·
[NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack) ·
[Tab navigation](https://developer.apple.com/documentation/swiftui/enhancing-your-app-content-with-tab-navigation) ·
[MapKit for SwiftUI](https://developer.apple.com/documentation/mapkit/mapkit-for-swiftui) ·
[MKMapItem.identifier](https://developer.apple.com/documentation/mapkit/mkmapitem/identifier-swift.property) ·
[ImageIO GPS](https://developer.apple.com/documentation/imageio/kcgimagemetadatashouldexcludegps) ·
[Scrollable stacks](https://developer.apple.com/documentation/swiftui/creating-performant-scrollable-stacks) ·
WWDC [25/256](https://developer.apple.com/videos/play/wwdc2025/256/), [25/306](https://developer.apple.com/videos/play/wwdc2025/306/),
[24/10097](https://developer.apple.com/videos/play/wwdc2024/10097/), [23/10043](https://developer.apple.com/videos/play/wwdc2023/10043/) ·
[iOS feature availability](https://www.apple.com/ios/feature-availability/) ·
[Required reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api) ·
[TestFlight](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview) ·
[Developer enrollment](https://developer.apple.com/programs/enroll/)

Swift Evolution: [SE-0466](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0466-control-default-actor-isolation.md) ·
[SE-0470](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0470-isolated-conformances.md)

Expert writing: [Ricouard: forget MVVM](https://dimillian.medium.com/swiftui-in-2025-forget-mvvm-262ff2bbd2ed) ·
[SwiftLee: MVVM](https://www.avanderlee.com/swiftui/mvvm-architectural-coding-pattern-to-structure-views/) ·
[Point-Free TCA FAQ](https://www.pointfree.co/blog/posts/141-composable-architecture-frequently-asked-questions) ·
[Majid: microapps](https://swiftwithmajid.com/2025/05/27/microapps-architecture-in-swift-scaling/) ·
[Nil Coalescing: @Observable init](https://nilcoalescing.com/blog/InitializingObservableClassesWithinTheSwiftUIHierarchy) ·
[Donny Wals: agentic pipeline](https://www.donnywals.com/setting-up-a-delivery-pipeline-for-your-agentic-iOS-projects/) ·
[Hacking with Swift: SwiftUI agent skill](https://www.hackingwithswift.com/articles/282/swiftui-agent-skill-claude-codex-ai) ·
[isowords modularisation](https://github.com/pointfreeco/isowords/discussions/115)

Process and backend: [DORA trunk-based](https://dora.dev/capabilities/trunk-based-development/) ·
[short-lived branches](https://trunkbaseddevelopment.com/short-lived-feature-branches/) ·
[GitHub plans](https://docs.github.com/en/get-started/learning-about-github/githubs-plans) ·
[Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions) ·
[Xcode Cloud](https://developer.apple.com/xcode-cloud/) · [agents.md](https://agents.md/) ·
[Claude Code best practices](https://code.claude.com/docs/en/best-practices) ·
[Firebase iOS release notes](https://firebase.google.com/support/release-notes/ios) ·
[Firebase Storage plan change](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024) ·
[Firestore offline](https://firebase.google.com/docs/firestore/manage-data/enable-offline) ·
[Firestore locations](https://firebase.google.com/docs/firestore/locations) ·
[Supabase pricing](https://supabase.com/pricing) ·
[Supabase regional blocks](https://supabase.com/blog/navigating-regional-network-blocks) ·
[supabase-swift](https://github.com/supabase/supabase-swift)

## Information architecture (`docs/IA.md`)

- HIG: [Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars) ·
  [Search fields](https://developer.apple.com/design/human-interface-guidelines/search-fields) ·
  [Modality](https://developer.apple.com/design/human-interface-guidelines/modality) ·
  [Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets) ·
  [Notifications](https://developer.apple.com/design/human-interface-guidelines/notifications)
- Apple: [Tab navigation](https://developer.apple.com/documentation/swiftui/enhancing-your-app-content-with-tab-navigation) ·
  [WWDC25 256](https://developer.apple.com/videos/play/wwdc2025/256/) ·
  [feature availability (no Look Around in India)](https://www.apple.com/ios/feature-availability/) ·
  [sheets cover the tab bar: Forums 711702](https://developer.apple.com/forums/thread/711702)
- Comparable apps: Instagram ([Engadget](https://www.engadget.com/social-media/instagram-tests-new-layout-that-puts-the-spotlight-on-reels-and-dms-215407062.html)) ·
  Snapchat ([TechCrunch 2024](https://techcrunch.com/2024/09/17/snapchat-tests-simple-version-of-the-app-without-snap-map-or-stories-tab)) ·
  Strava ([BikeRumor](https://bikerumor.com/strava-redesigns-their-app-navigation-to-make-it-easier-to-track-rides-find-friends)) ·
  AllTrails ([support](https://support.alltrails.com/hc/en-us/articles/44409942124052-Understanding-the-AllTrails-App)) ·
  Komoot ([redesign 2025](https://newsroom.komoot.com/254263-komoot-unveils-modern-design-as-part-of-ambitious-product-roadmap/)) ·
  Partiful ([Pratt critique](https://ixd.prattsi.org/2025/02/design-critique-partiful/)) ·
  Google Maps ([9to5Google](https://9to5google.com/2024/07/31/google-maps-bottom-bar-redesign-rolling-out/)) ·
  District by Zomato ([OfficeChai](https://officechai.com/startups/zomato-launches-its-going-out-app-district/)) ·
  India ([YouGov 2024](https://yougov.com/reports/49047-india-media-morph-2024-trend-report), medium confidence)

## Data model (`docs/DATA-MODEL.md`)

- Apple: [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults) ·
  [File System Basics](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html) ·
  [Keychain generic password](https://developer.apple.com/documentation/security/ksecclassgenericpassword) ·
  [@Query only in Views (forum 811232)](https://developer.apple.com/forums/thread/811232) ·
  [What's new in SwiftData, WWDC24](https://developer.apple.com/videos/play/wwdc2024/10137/) ·
  [SwiftData on iOS 18 memory (forum 761522)](https://developer.apple.com/forums/thread/761522) ·
  [Returning to Core Data](https://mjtsai.com/blog/2024/10/16/returning-to-core-data/) ·
  [Fatbobman: before using SwiftData](https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/) ·
  [Hacking with Swift: SwiftData and concurrency](https://www.hackingwithswift.com/quick-start/swiftdata/how-swiftdata-works-with-swift-concurrency) ·
  [NWPathMonitor](https://developer.apple.com/documentation/network/nwpathmonitor)
- Firebase: [Offline data](https://firebase.google.com/docs/firestore/manage-data/enable-offline) ·
  [Best practices (IDs)](https://firebase.google.com/docs/firestore/best-practices) ·
  [Swift Codable mapping](https://firebase.google.com/docs/firestore/solutions/swift-codable-data-mapping) ·
  [Quotas](https://firebase.google.com/docs/firestore/quotas) · [Queries](https://firebase.google.com/docs/firestore/query-data/queries) ·
  [Rules are not filters](https://firebase.google.com/docs/firestore/security/rules-query) ·
  [Counters](https://firebase.google.com/docs/firestore/solutions/counters) ·
  [Aggregation queries](https://firebase.google.com/docs/firestore/query-data/aggregation-queries) ·
  [Structure data](https://firebase.google.com/docs/firestore/manage-data/structure-data)
- Supabase: [Row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security) ·
  [Realtime Postgres changes](https://supabase.com/docs/guides/realtime/postgres-changes)

## Risks, safety and legal (`docs/RISKS.md`)

Market: [StatCounter India](https://gs.statcounter.com/os-market-share/mobile/india) ·
[TechCrunch: iPhone in India 2025](https://techcrunch.com/2026/01/23/apple-iphone-just-had-its-best-year-in-india-as-the-smartphone-market-stays-broadly-flat) ·
[EE Times India / IDC](https://www.eetindia.co.in/idc-india-smartphone-market-flat-in-2025/) ·
[Partiful](https://apps.apple.com/app/id1662982304) ·
[Clubhouse Android in India](https://businesstoday.in/technology/story/clubhouse-is-coming-to-indian-android-users-on-may-21-296289-2021-05-17)
· Name: [Vybe: Go Out Smarter](https://apps.apple.com/us/app/-/id6762636915) ·
[Vybe - The Going Out App](https://apps.apple.com/app/id1668442386) ·
[App name rules](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
· Growth: [Andrew Chen interview](https://techcrunch.com/2021/12/08/andrew-chen-of-a16z-on-how-startups-get-past-a-cold-start-to-survive-and-thrive) ·
[a16z social benchmarks](https://a16z.com/2023/03/03/how-to-benchmark-your-social-app) ·
[WhatsApp link previews](https://developers.facebook.com/documentation/business-messaging/whatsapp/link-previews/)
· Competitors: [District](https://www.medianama.com/2026/01/223-eternal-doubling-down-district-despite-rising-losses/) ·
[Swiggy Scenes](https://www.medianama.com/2024/12/223-swiggy-launches-live-events-vertical-scenes-takes-on-zomato-district/) ·
[Instagram Map India](https://about.fb.com/news/2025/10/now-in-india-instagram-rolls-out-map-feature-to-help-people-connect-with-friends/)
· Location safety: [Strava 2018](https://www.helpnetsecurity.com/2018/01/29/strava-user-heatmap-reveals-patterns-of-life-in-western-military-bases/) ·
[Strava 2024](https://fortune.com/2024/10/29/biden-trump-harris-confidential-movements-fitness-app-strava-le-monde) ·
[KU Leuven](https://www.darkreading.com/application-security/popular-fitness-apps-leak-location-data-even-when-users-set-privacy-zones) ·
[ICWSM home inference](https://ojs.aaai.org/index.php/ICWSM/article/view/14762)
· Harassment: [Amnesty India](https://www.amnesty.org.uk/press-releases/india-women-politicians-face-shocking-scale-abuse-twitter-new-research) ·
[IT for Change](https://ruralindiaonline.org/en/library/resource/born-digital-born-free-a-socio-legal-study-on-young-womens-experiences-of-online-violence-in-south-india/) ·
[Bumble India](https://www.businessinsider.in/advertising/ad-tech/news/at-bumble-safety-is-our-number-one-priority-priti-joshi-bumble/articleshow/81670547.cms)
· Age and App Store: [age ratings](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/) ·
[age assurance](https://developer.apple.com/support/age-assurance) ·
[App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) ·
[upcoming requirements](https://developer.apple.com/news/upcoming-requirements/)
· Treks: [Rajgad](https://www.freepressjournal.in/pune/tragedy-at-rajgad-21-year-old-pune-woman-falls-400-feet-to-her-death-during-trek) ·
[monsoon bans](https://www.punekarnews.in/?p=210286) · [Bhushi Dam 2024](https://en.wikipedia.org/wiki/2024_Lonavala_waterfall_tragedy)
· Law: [IT Amendment Rules 2026](https://www.khaitanco.com/thought-leadership/MeitY-notifies-the-IT-Amendment-Rules-2026) ·
[IT Rules 2021](https://trilegal.com/knowledge-repository/information-technology-rules-2021/) ·
[CERT-In](https://www.mondaq.com/india/it-and-internet/1270362/6-hours-to-report-cyber-incidents-to-cert-in-and-more-compliances) ·
[Tele-MANAS](https://pib.gov.in/PressReleasePage.aspx?PRID=2022057)
· Security: [Tea app breach](https://www.404media.co/women-dating-safety-app-tea-breached-users-ids-posted-to-4chan/) ·
[Firebase insecure rules](https://firebase.google.com/docs/firestore/security/insecure-rules) ·
[Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security) ·
[DeviceCheck](https://developer.apple.com/documentation/devicecheck)

## How we work (`docs/PROCESS.md`)

[YC: how to build an MVP](https://ycombinator.com/library/Io-how-to-build-an-mvp) ·
[NN/g: test with 5 users](https://nngroup.com/articles/why-you-only-need-to-test-with-5-users/) ·
[Figma Education plan](https://help.figma.com/hc/en-us/articles/360041061214) ·
[Figma Code Connect](https://developers.figma.com/docs/code-connect) ·
[Linear for small teams](https://linear.app/docs/how-to-use-linear-small-teams) ·
[Shape Up](https://basecamp.com/shapeup/0.3-chapter-01) · [Given/When/Then](https://martinfowler.com/bliki/GivenWhenThen.html) ·
[Decision records (arc42)](https://docs.arc42.org/tips/9-5/) ·
[Google code review standard](https://google.github.io/eng-practices/review/reviewer/standard.html) ·
[Feature toggles](https://martinfowler.com/articles/feature-toggles.html) ·
[Firebase environments](https://firebase.google.com/docs/projects/dev-workflows/overview-environments) ·
[OWASP MASWE-0005](https://mas.owasp.org/MASWE/MASVS-AUTH/MASWE-0005/) ·
[DORA 2025](https://cloud.google.com/blog/products/ai-machine-learning/announcing-the-2025-dora-report) ·
[Claude Code best practices](https://code.claude.com/docs/en/best-practices) ·
[Thoughtworks Radar](https://www.thoughtworks.com/about-us/news/2025/thoughtworks-technology-radar-highlights-genai-s-impact-and-key-) ·
[Veracode AI code study](https://www.veracode.com/press-release/ai-generated-code-poses-major-security-risks-in-nearly-half-of-all-development-tasks-veracode-research-reveals/) ·
[WWDC23 accessibility audits](https://developer.apple.com/videos/play/wwdc2023/10035/) ·
[App Store phased release](https://developer-mdn.apple.com/help/app-store-connect/update-your-app/release-a-version-update-in-phases) ·
[Xcode crash reports](https://developer.apple.com/documentation/xcode/acquiring-crash-reports-and-diagnostic-logs) ·
[TestFlight feedback](https://www.developer.apple.com/help/app-store-connect/test-a-beta-version/view-tester-feedback) ·
[Google SRE postmortems](https://sre.google/sre-book/postmortem-culture/) ·
[Shopify mobile releases](https://shopify.engineering/mobile-release-engineering-scale-shipit-mobile)

## Before and while building (`docs/BEFORE-BUILD.md`)

[Walking skeleton](https://codeclimate.com/blog/kickstart-your-next-project-with-a-walking-skeleton) ·
[Shape Up: circuit breaker](https://basecamp.com/shapeup/3.5-chapter-14) · [Shape Up: appetite](https://basecamp.com/shapeup/1.2-chapter-03) ·
[Local packages](https://developer.apple.com/documentation/xcode/organizing-your-code-with-local-packages) ·
[Previews broken in packages (forums 820802)](https://developer.apple.com/forums/thread/820802) ·
[UIBackgroundModes is a plist key (forums 787026)](https://developer.apple.com/forums/thread/787026) ·
[Developer enrollment](https://developer.apple.com/programs/enroll/) ·
[Enrollment problems in India (forums 837697)](https://developer.apple.com/forums/thread/837697) ·
[Claude Code best practices](https://code.claude.com/docs/en/best-practices) ·
[Donny Wals: agentic iOS pipeline](https://www.donnywals.com/setting-up-a-delivery-pipeline-for-your-agentic-iOS-projects/) ·
[CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) ·
[Branch protection plans](https://docs.github.com/en/get-started/learning-about-github/githubs-plans)

## Motion and haptics (`docs/MOTION.md`)

HIG: [Motion](https://developer.apple.com/design/human-interface-guidelines/motion) ·
[Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) ·
[Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics) ·
[Materials](https://developer.apple.com/design/human-interface-guidelines/materials) · WWDC:
[Animate with springs 23](https://developer.apple.com/videos/play/wwdc2023/10158/) ·
[Advanced animations 23](https://developer.apple.com/videos/play/wwdc2023/10157/) ·
[UI animations and transitions 24](https://developer.apple.com/videos/play/wwdc2024/10145/) ·
[Custom visual effects 24](https://developer.apple.com/videos/play/wwdc2024/10151/) ·
[SF Symbols 6](https://developer.apple.com/videos/play/wwdc2024/10188/) · [New design 25](https://developer.apple.com/videos/play/wwdc2025/323/) ·
Apple docs: [navigationTransition](https://developer.apple.com/documentation/swiftui/view/navigationtransition(_:)) ·
[Animation.default](https://developer.apple.com/documentation/swiftui/animation/default) ·
[ProMotion](https://developer.apple.com/documentation/quartzcore/optimizing-iphone-and-ipad-apps-to-support-promotion-displays) ·
Design systems: [IBM Carbon](https://carbondesignsystem.com/elements/motion/overview/) ·
[Atlassian](https://atlassian.design/foundations/motion/applying-motion) ·
[Atlassian lint rule](https://atlassian.design/components/eslint-plugin-design-system/use-tokens-motion/usage) ·
[Material MotionScheme](https://developer.android.com/reference/kotlin/androidx/compose/material3/MotionScheme) ·
Figma: [Smart Animate](https://help.figma.com/hc/en-us/articles/360039818874) ·
[Spring animations](https://help.figma.com/hc/en-us/articles/360051748654) · Writing:
[Emil Kowalski](https://emilkowal.ski/ui/you-dont-need-animations) ·
[Use Your Loaf](https://useyourloaf.com/blog/reducing-motion-of-animations/) ·
[Fatbobman](https://fatbobman.com/en/snippet/swiftui-implicit-vs-explicit-animations/) ·
[Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-haptic-effects-using-sensory-feedback)
