import Foundation

/// One day's cell in the contribution grid.
public struct GridCell: Equatable, Sendable {
    /// Start of the calendar day this cell represents.
    public let date: Date
    /// How many times the habit was completed that day.
    public let count: Int
    /// Shading bucket, `0...4` like GitHub (0 = empty, 4 = most active).
    public let level: Int

    public init(date: Date, count: Int, level: Int) {
        self.date = date
        self.count = count
        self.level = level
    }
}

/// A contribution heatmap laid out as columns of weeks.
///
/// `weeks[column][row]` — `column` runs left→right (oldest week first), `row` is the
/// weekday slot `0...6` aligned to the calendar's `firstWeekday`. A `nil` slot is a day
/// outside the requested range (e.g. future days in the current, partial week).
public struct ContributionGrid: Equatable, Sendable {
    public let weeks: [[GridCell?]]

    public init(weeks: [[GridCell?]]) {
        self.weeks = weeks
    }

    /// Every real (non-nil) cell, oldest first.
    public var cells: [GridCell] {
        weeks.flatMap { $0.compactMap { $0 } }
    }
}

public enum ContributionGridBuilder {
    /// Builds a grid of `weeks` columns ending on the week that contains `end`.
    ///
    /// - Parameters:
    ///   - end: The most recent day to include (typically "today"). Days after this in
    ///     the final column are left `nil`.
    ///   - weeks: Number of week-columns to show (GitHub shows ~53).
    ///   - counts: Per-day completion counts, keyed by any instant within the day.
    ///   - calendar: Calendar used for day/week boundaries. Inject a fixed one in tests.
    ///   - levelThresholds: Ascending counts at which the shading steps up to 1,2,3,4.
    ///     Default `[1,2,4,6]`: 1→L1, 2–3→L2, 4–5→L3, 6+→L4.
    public static func build(
        endingOn end: Date,
        weeks weekCount: Int,
        counts: [Date: Int],
        calendar: Calendar = .current,
        levelThresholds: [Int] = [1, 2, 4, 6]
    ) -> ContributionGrid {
        precondition(weekCount > 0, "weekCount must be positive")

        let endDay = calendar.startOfDay(for: end)

        // Normalize the supplied counts to start-of-day keys so lookups are exact.
        var countByDay: [Date: Int] = [:]
        for (day, n) in counts {
            countByDay[calendar.startOfDay(for: day), default: 0] += n
        }

        // First day of the week that `end` falls in, then walk back to the first column.
        guard
            let endWeekStart = calendar.dateInterval(of: .weekOfYear, for: endDay)?.start,
            let firstColumnStart = calendar.date(
                byAdding: .weekOfYear, value: -(weekCount - 1), to: endWeekStart
            )
        else {
            return ContributionGrid(weeks: [])
        }

        var weeks: [[GridCell?]] = []
        weeks.reserveCapacity(weekCount)

        for column in 0..<weekCount {
            var week: [GridCell?] = []
            week.reserveCapacity(7)
            for row in 0..<7 {
                guard
                    let day = calendar.date(
                        byAdding: .day, value: column * 7 + row, to: firstColumnStart
                    )
                else {
                    week.append(nil)
                    continue
                }
                // Future days (past `end`) are left blank.
                if day > endDay {
                    week.append(nil)
                    continue
                }
                let count = countByDay[day] ?? 0
                week.append(GridCell(date: day, count: count, level: level(for: count, thresholds: levelThresholds)))
            }
            weeks.append(week)
        }

        return ContributionGrid(weeks: weeks)
    }

    /// Maps a raw count to a `0...4` shading level via ascending thresholds.
    static func level(for count: Int, thresholds: [Int]) -> Int {
        guard count > 0 else { return 0 }
        var level = 1
        for threshold in thresholds where count >= threshold {
            level = thresholds.firstIndex(of: threshold).map { $0 + 1 } ?? level
        }
        return min(level, 4)
    }
}
