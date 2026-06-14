import SwiftUI

// SwiftUI's Color can't be built from a hex string out of the box, but our habits store
// their color as a hex string (e.g. "#39D353"). This adds that convenience initializer.
extension Color {
    init(hex: String) {
        // Drop a leading "#" if present, then parse the 6 hex digits as RRGGBB.
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255
        let green = Double((rgb >> 8) & 0xFF) / 255
        let blue = Double(rgb & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
