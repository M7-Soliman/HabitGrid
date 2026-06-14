import Foundation

// The fixed set of colors a habit can use. A curated palette looks cleaner and more
// "designed" than a full color wheel, and maps straight to the hex we store.
enum HabitPalette {
    static let colors: [String] = [
        "#39D353", // green
        "#3FB9B0", // teal
        "#4F9DDE", // blue
        "#7A82E8", // indigo
        "#B660E0", // purple
        "#E0556E", // pink
        "#E8923C", // orange
        "#E6C84F", // yellow
    ]

    static var `default`: String { colors[0] }
}
