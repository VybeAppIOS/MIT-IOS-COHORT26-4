// Fixture: Models never import UI frameworks.
import Foundation
import UIKit // expect: no_ui_import_in_logic

struct PlaceFixture: Codable { let times: RunTimes? }
