import Foundation

/// A record that a habit was completed on a given day.
///
/// One `Completion` per "tick". A habit can be ticked more than once a day (e.g. two
/// workouts), which is what gives the grid its intensity levels.
public struct Completion: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var habitID: UUID
    /// The moment it was logged. The grid buckets this into a calendar day.
    public var date: Date

    public init(id: UUID = UUID(), habitID: UUID, date: Date = Date()) {
        self.id = id
        self.habitID = habitID
        self.date = date
    }
}

public extension Sequence where Element == Completion {
    /// Collapses completions for one habit into a per-day count keyed by the start of
    /// each day, ready to feed into ``ContributionGridBuilder``.
    func dailyCounts(for habitID: UUID, calendar: Calendar = .current) -> [Date: Int] {
        reduce(into: [:]) { counts, completion in
            guard completion.habitID == habitID else { return }
            let day = calendar.startOfDay(for: completion.date)
            counts[day, default: 0] += 1
        }
    }
}
