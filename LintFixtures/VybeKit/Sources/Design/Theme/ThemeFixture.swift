// Fixture (must pass): raw colours and animation curves are allowed only in Design/Theme.
import SwiftUI

enum ThemeFixture {
    static let brand = Color(red: 0.95, green: 0.36, blue: 0.48)
    static let brandHex = "#F25C7A"
    static let standard = Animation.spring(duration: 0.35)
    static let quick = Animation.easeInOut(duration: 0.2)
}
