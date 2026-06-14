import Foundation

/// Streak calculations over per-day completion counts.
///
/// Pure functions on `[Date: Int]` (the same shape ``ContributionGridBuilder`` consumes),
/// so they're fully testable without any UI or database.
public enum Streaks {

    /// The current run of consecutive days ending today that **meet** `metThreshold`
    /// (the habit's daily target; default 1 = "logged at least once").
    ///
    /// If *today* doesn't meet the goal yet, the streak is measured from *yesterday* — so an
    /// active streak isn't prematurely zeroed just because you haven't finished today.
    public static func current(
        asOf date: Date = Date(),
        counts: [Date: Int],
        calendar: Calendar = .current,
        metThreshold: Int = 1
    ) -> Int {
        let goal = max(metThreshold, 1)
        let byDay = normalize(counts, calendar: calendar)

        var day = calendar.startOfDay(for: date)
        if (byDay[day] ?? 0) < goal {
            // Grace for "today not done yet": start counting from yesterday.
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        var streak = 0
        while (byDay[day] ?? 0) >= goal {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    /// The longest run of consecutive goal-meeting days ever recorded.
    public static func longest(
        counts: [Date: Int],
        calendar: Calendar = .current,
        metThreshold: Int = 1
    ) -> Int {
        let goal = max(metThreshold, 1)
        let days = normalize(counts, calendar: calendar)
            .filter { $0.value >= goal }
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

    // MARK: - Quit habits (logging is a "slip"; clean days are the win)

    /// Days clean: consecutive days ending `asOf` with no slip (count 0), bounded by `start`.
    /// Returns 0 if there was a slip today.
    public static func cleanStreak(
        asOf date: Date = Date(),
        counts: [Date: Int],
        calendar: Calendar = .current,
        start: Date
    ) -> Int {
        let byDay = normalize(counts, calendar: calendar)
        let startDay = calendar.startOfDay(for: start)
        var day = calendar.startOfDay(for: date)
        var streak = 0
        while day >= startDay && (byDay[day] ?? 0) == 0 {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    /// Fraction (0...1) of days from `start` to `asOf` that were clean (no slip).
    public static func cleanRate(
        counts: [Date: Int],
        from start: Date,
        asOf date: Date = Date(),
        calendar: Calendar = .current
    ) -> Double {
        let byDay = normalize(counts, calendar: calendar)
        var day = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: date)
        guard endDay >= day else { return 0 }
        var total = 0, clean = 0
        while day <= endDay {
            total += 1
            if (byDay[day] ?? 0) == 0 { clean += 1 }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return total > 0 ? Double(clean) / Double(total) : 0
    }

    /// Longest run of consecutive clean days between `start` and `asOf`.
    public static func longestClean(
        counts: [Date: Int],
        from start: Date,
        asOf date: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let byDay = normalize(counts, calendar: calendar)
        var day = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: date)
        guard endDay >= day else { return 0 }
        var longest = 0, run = 0
        while day <= endDay {
            if (byDay[day] ?? 0) == 0 { run += 1; longest = max(longest, run) } else { run = 0 }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return longest
    }

    /// The fraction (0...1) of the last `days` days (ending `asOf`) that met the goal.
    /// E.g. metRate over 30 days = your 30-day consistency.
    public static func metRate(
        counts: [Date: Int],
        lastDays days: Int,
        asOf date: Date = Date(),
        calendar: Calendar = .current,
        metThreshold: Int = 1
    ) -> Double {
        guard days > 0 else { return 0 }
        let goal = max(metThreshold, 1)
        let byDay = normalize(counts, calendar: calendar)
        let start = calendar.startOfDay(for: date)

        var met = 0
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: start) else { continue }
            if (byDay[day] ?? 0) >= goal { met += 1 }
        }
        return Double(met) / Double(days)
    }

    /// Collapses arbitrary-instant keys into start-of-day buckets.
    private static func normalize(_ counts: [Date: Int], calendar: Calendar) -> [Date: Int] {
        counts.reduce(into: [:]) { result, pair in
            result[calendar.startOfDay(for: pair.key), default: 0] += pair.value
        }
    }
}
