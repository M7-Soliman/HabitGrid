import Foundation

/// Streak calculations over per-day completion counts.
///
/// Pure functions on `[Date: Int]` (the same shape ``ContributionGridBuilder`` consumes),
/// so they're fully testable without any UI or database.
public enum Streaks {

    /// The current run of consecutive completed days ending today.
    ///
    /// "Completed" means count > 0. If *today* isn't done yet, the streak is measured from
    /// *yesterday* — so an active streak isn't prematurely zeroed just because you haven't
    /// logged today. Returns 0 if neither today nor yesterday is completed.
    public static func current(
        asOf date: Date = Date(),
        counts: [Date: Int],
        calendar: Calendar = .current
    ) -> Int {
        let byDay = normalize(counts, calendar: calendar)

        var day = calendar.startOfDay(for: date)
        if (byDay[day] ?? 0) == 0 {
            // Grace for "today not logged yet": start counting from yesterday.
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        var streak = 0
        while (byDay[day] ?? 0) > 0 {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    /// The longest run of consecutive completed days ever recorded.
    public static func longest(
        counts: [Date: Int],
        calendar: Calendar = .current
    ) -> Int {
        let days = normalize(counts, calendar: calendar)
            .filter { $0.value > 0 }
            .keys
            .sorted()
        guard let first = days.first else { return 0 }

        var longest = 1
        var run = 1
        var previous = first
        for day in days.dropFirst() {
            if let next = calendar.date(byAdding: .day, value: 1, to: previous),
               calendar.isDate(next, inSameDayAs: day) {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
            previous = day
        }
        return longest
    }

    /// Collapses arbitrary-instant keys into start-of-day buckets.
    private static func normalize(_ counts: [Date: Int], calendar: Calendar) -> [Date: Int] {
        counts.reduce(into: [:]) { result, pair in
            result[calendar.startOfDay(for: pair.key), default: 0] += pair.value
        }
    }
}
