// Fixture (must pass): the app target may use @AppStorage and AppDependencies.
import SwiftUI

struct VybeAppFixture: View {
    @AppStorage("onboarded") var onboarded = false
    let deps = AppDependencies.preview
    var body: some View { Text("Vybe") }
}
