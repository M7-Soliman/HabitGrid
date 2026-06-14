import Foundation

// Habit colors, borrowed from the Belora spec's role-color palette — a curated,
// well-balanced set that looks intentional in both light and dark mode.
enum HabitPalette {
    static let colors: [String] = [
        "#818CF8", // indigo
        "#A78BFA", // violet
        "#FB7185", // rose
        "#FB923C", // orange
        "#E879F9", // fuchsia
        "#22D3EE", // cyan
        "#FDCA40", // gold
        "#A8C5F5", // brand blue
    ]

    static var `default`: String { colors[0] }
}
