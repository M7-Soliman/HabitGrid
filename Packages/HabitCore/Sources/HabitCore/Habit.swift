import Foundation

/// A habit the user wants to track (e.g. "Gym", "Read", "No snooze").
///
/// This is a plain value type with no persistence framework attached. The app target
/// maps these to/from a SwiftData `@Model`; keeping the domain model pure lets us unit
/// test all the interesting logic without a database or a running app.
public struct Habit: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    /// Hex color used to tint this habit's grid, e.g. GitHub green `#39D353`.
    public var colorHex: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#39D353",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
}
