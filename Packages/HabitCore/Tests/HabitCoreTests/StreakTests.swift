import XCTest
@testable import HabitCore

final class StreakTests: XCTestCase {

    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.firstWeekday = 1
        return cal
    }()

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d))!
    }

    func testCurrentStreakCountsConsecutiveDaysEndingToday() {
        let counts = [day(2026, 6, 11): 1, day(2026, 6, 12): 1, day(2026, 6, 13): 2]
        XCTAssertEqual(Streaks.current(asOf: day(2026, 6, 13), counts: counts, calendar: calendar), 3)
    }

    func testCurrentStreakSurvivesWhenTodayNotYetLogged() {
        // Today (13th) unlogged, but 11th & 12th done -> streak still 2, not 0.
        let counts = [day(2026, 6, 11): 1, day(2026, 6, 12): 1]
        XCTAssertEqual(Streaks.current(asOf: day(2026, 6, 13), counts: counts, calendar: calendar), 2)
    }

    func testCurrentStreakIsZeroWhenTodayAndYesterdayMissed() {
        let counts = [day(2026, 6, 10): 1]
        XCTAssertEqual(Streaks.current(asOf: day(2026, 6, 13), counts: counts, calendar: calendar), 0)
    }

    func testGapBreaksTheStreak() {
        // 13th and 12th done, 11th missed -> current streak is 2.
        let counts = [day(2026, 6, 10): 1, day(2026, 6, 12): 1, day(2026, 6, 13): 1]
        XCTAssertEqual(Streaks.current(asOf: day(2026, 6, 13), counts: counts, calendar: calendar), 2)
    }

    func testLongestStreakFindsTheBiggestRun() {
        // Runs: [1,2,3] (len 3), [10,11] (len 2). Longest = 3.
        let counts = [
            day(2026, 6, 1): 1, day(2026, 6, 2): 1, day(2026, 6, 3): 1,
            day(2026, 6, 10): 1, day(2026, 6, 11): 1,
        ]
        XCTAssertEqual(Streaks.longest(counts: counts, calendar: calendar), 3)
    }

    func testLongestStreakIsZeroForNoCompletions() {
        XCTAssertEqual(Streaks.longest(counts: [:], calendar: calendar), 0)
    }
}
