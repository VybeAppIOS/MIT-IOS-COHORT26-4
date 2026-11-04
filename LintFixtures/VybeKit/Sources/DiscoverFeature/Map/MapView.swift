// Fixture: a feature View that breaks the style rules. Lines tagged `expect:` must be caught.
import SwiftUI

struct MapView: View {
    @AppStorage("seenTip") var seenTip = false // expect: no_app_storage_outside_app
    let deps: AppDependencies // expect: app_dependencies_scope
    let times: RunTimes? = nil // expect: run_times_confined
    let accentHex = "#1A2B3C" // expect: no_hex_color_string

    var body: some View {
        NavigationView { // expect: no_deprecated_api
            Text("Discover")
                .foregroundColor(.red) // expect: no_deprecated_api
                .background(Color(red: 1, green: 0, blue: 0)) // expect: no_hardcoded_color
                .overlay(Color(hex: accentHex)) // expect: no_hardcoded_color
                .background(Color(.sRGB, red: 1, green: 0, blue: 0)) // expect: no_hardcoded_color
                .overlay(Color(hue: 0.5, saturation: 1, brightness: 1)) // expect: no_hardcoded_color
                .font(.system(size: 14)) // expect: no_system_font_size
                .animation(.easeInOut, value: seenTip) // expect: no_raw_animation_curve
                .animation(.spring(duration: 0.3), value: seenTip) // expect: no_raw_animation_curve
                .animation(Animation.linear(duration: 1), value: seenTip) // expect: no_raw_animation_curve
            NavigationLink(destination: Text("Spot")) { Text("Open") } // expect: no_deprecated_api
            // Must pass: a Theme token animation, a view inside a View file, a linear progress style.
            ProgressView().progressViewStyle(.linear)
        }
    }

    func tapped() {
        withAnimation { seenTip = true } // expect: no_bare_with_animation
        withAnimation() { seenTip = false } // expect: no_bare_with_animation
        withAnimation(Theme.Motion.standard) { seenTip = true }
        print("tapped") // expect: no_print
        debugPrint(seenTip) // expect: no_print
        _ = fingerprint(of: accentHex)
        _ = UIApplication.shared.canOpenURL(url) // expect: no_can_open_url
        // Must pass: print("x"), canOpenURL and Color(red: 0) inside a comment.
        _ = "print(x) and Color(red: 0) inside a string"
    }
}

final class OldMapModel: ObservableObject {} // expect: no_deprecated_api
public struct LeakedMapType {} // expect: public_only_in_screens
let oldItem = MKMapItem(placemark: mark) // expect: no_deprecated_api
