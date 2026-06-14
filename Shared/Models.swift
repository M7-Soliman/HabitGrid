import Foundation
import SwiftData

// SwiftData storage models. These are `class`es (reference types) because the database
// needs one canonical, observable object per row — the case where a class beats a struct.
// HabitCore's pure structs stay separate; these persist; the two meet at [Date: Int].

// A habit row in the on-device database.
@Model
final class HabitModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String          // user-chosen color, e.g. "#39D353"
    var dailyTarget: Int          // goal count per day (1 = a plain yes/no habit)
    var sortIndex: Int            // manual ordering in the list (lower = higher up)
    var createdAt: Date

    // One habit has many completions. Deleting a habit cascades to delete its completions.
    @Relationship(deleteRule: .cascade, inverse: \CompletionModel.habit)
    var completions: [CompletionModel]

    init(id: UUID = UUID(), name: String, colorHex: String = "#39D353", dailyTarget: Int = 1, sortIndex: Int = 0, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.dailyTarget = dailyTarget
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.completions = []
    }
}

// One "tick" — the habit was done at this moment. Many of these per habit.
@Model
final class CompletionModel {
    var id: UUID
    var date: Date
    var habit: HabitModel?        // the habit this tick belongs to (set via the relationship)

    init(id: UUID = UUID(), date: Date = Date(), habit: HabitModel? = nil) {
        self.id = id
        self.date = date
        self.habit = habit
    }
}
