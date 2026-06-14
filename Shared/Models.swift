import Foundation
import SwiftData

// SwiftData storage models. These are `class`es (reference types) because the database
// needs one canonical, observable object per row — the case where a class beats a struct.
// HabitCore's pure structs stay separate; these persist; the two meet at [Date: Int].

// Build a good habit (log when you do it) vs quit a bad one (log a "slip"; clean days are good).
enum HabitKind: String, Codable, CaseIterable {
    case build
    case quit
}

// A habit row in the on-device database.
@Model
final class HabitModel {
    // CloudKit requires: no .unique constraints, and every property has a default value.
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "#A8C5F5"   // user-chosen color
    var dailyTarget: Int = 1           // goal count per day (1 = a plain yes/no habit)
    var sortIndex: Int = 0             // manual ordering in the list (lower = higher up)
    var kindRaw: String = HabitKind.build.rawValue   // "build" or "quit" (String for CloudKit)
    var createdAt: Date = Date()

    // Typed accessor for the kind.
    var kind: HabitKind {
        get { HabitKind(rawValue: kindRaw) ?? .build }
        set { kindRaw = newValue.rawValue }
    }

    // One habit has many completions. Deleting a habit cascades to delete its completions.
    // CloudKit requires relationships to be optional, hence `[CompletionModel]?`.
    @Relationship(deleteRule: .cascade, inverse: \CompletionModel.habit)
    var completions: [CompletionModel]?

    init(id: UUID = UUID(), name: String, colorHex: String = "#39D353", dailyTarget: Int = 1, sortIndex: Int = 0, kind: HabitKind = .build, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.dailyTarget = dailyTarget
        self.sortIndex = sortIndex
        self.kindRaw = kind.rawValue
        self.createdAt = createdAt
        self.completions = []
    }
}

extension HabitModel {
    /// Non-optional view of the (CloudKit-optional) completions relationship.
    var completionsList: [CompletionModel] { completions ?? [] }
}

// One "tick" — the habit was done at this moment. Many of these per habit.
@Model
final class CompletionModel {
    var id: UUID = UUID()
    var date: Date = Date()
    var habit: HabitModel?        // the habit this tick belongs to (set via the relationship)

    init(id: UUID = UUID(), date: Date = Date(), habit: HabitModel? = nil) {
        self.id = id
        self.date = date
        self.habit = habit
    }
}
