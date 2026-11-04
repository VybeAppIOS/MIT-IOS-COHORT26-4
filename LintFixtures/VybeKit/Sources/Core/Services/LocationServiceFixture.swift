// Fixture: Core rules (imports, @MainActor, unsafe concurrency).
import CoreLocation
import Foundation
import SwiftUI // expect: no_ui_import_in_logic

@MainActor final class LocationThing {} // expect: main_actor_in_core
final class Box: @unchecked Sendable {} // expect: unsafe_concurrency_needs_reason
nonisolated(unsafe) var counter = 0 // expect: unsafe_concurrency_needs_reason
func hop() { MainActor.assumeIsolated { } } // expect: unsafe_concurrency_needs_reason
@unsafe func rawPointerWork() {} // expect: unsafe_concurrency_needs_reason

// Must pass: a reason on the same line, the words in a comment, and Core-only types.
final class Cache: @unchecked Sendable {} // allowed: guarded by a lock, approved by Lohitaksh 4 Nov
// Never write @unchecked Sendable or nonisolated(unsafe) without a reason.
let coreDeps: AppDependencies? = nil
let coreTimes: RunTimes? = nil
