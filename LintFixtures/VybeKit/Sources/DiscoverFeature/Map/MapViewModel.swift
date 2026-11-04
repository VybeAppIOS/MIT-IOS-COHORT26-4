// Fixture: a ViewModel must not import UI frameworks.
import Foundation
import Observation
import SwiftUI // expect: no_ui_import_in_logic
@preconcurrency import MapKit // expect: no_ui_import_in_logic
import struct UIKit.UIColor // expect: no_ui_import_in_logic

@MainActor @Observable final class MapViewModel {}
