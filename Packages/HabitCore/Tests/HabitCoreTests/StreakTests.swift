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

    func testCurrentStreakRespectsTarget() {
        // target 2: today=2 (met), yesterday=1 (missed) -> streak of 1.
        let counts = [day(2026, 6, 12): 1, day(2026, 6, 13): 2]
        XCTAssertEqual(Streaks.current(asOf: day(2026, 6, 13), counts: counts, calendar: calendar, metThreshold: 2), 1)

        // all three days meet the goal of 2.
        let counts2 = [day(2026, 6, 11): 2, day(2026, 6, 12): 3, day(2026, 6, 13): 2]
        XCTAssertEqual(Streaks.current(asOf: day(2026, 6, 13), counts: counts2, calendar: calendar, metThreshold: 2), 3)
    }

    func testLongestStreakRespectsTarget() {
        // With goal 2: runs meeting it are [Jun1,Jun2] (2) and [Jun4] (1) -> longest 2.
        let counts = [day(2026, 6, 1): 2, day(2026, 6, 2): 2, day(2026, 6, 3): 1, day(2026, 6, 4): 2]
        XCTAssertEqual(Streaks.longest(counts: counts, calendar: calendar, metThreshold: 2), 2)
    }

    func testMetRateOverLastDays() {
        // Last 4 days (Jun 10–13): met on Jun 13 and Jun 11 -> 2 of 4 = 0.5.
        let counts = [day(2026, 6, 13): 1, day(2026, 6, 11): 1]
        XCTAssertEqual(
            Streaks.metRate(counts: counts, lastDays: 4, asOf: day(2026, 6, 13), calendar: calendar),
            0.5, accuracy: 0.0001
        )
    }

    func testMetRateRespectsTarget() {
        // Target 2 over 2 days: Jun13=2 (met), Jun12=1 (missed) -> 1 of 2 = 0.5.
        let counts = [day(2026, 6, 13): 2, day(2026, 6, 12): 1]
        XCTAssertEqual(
            Streaks.metRate(counts: counts, lastDays: 2, asOf: day(2026, 6, 13), calendar: calendar, metThreshold: 2),
            0.5, accuracy: 0.0001
        )
    }

    // MARK: Quit habits

    func testCleanStreak() {
        // Started Jun 1, no slips -> 13 days clean on Jun 13.
        XCTAssertEqual(Streaks.cleanStreak(asOf: day(2026, 6, 13), counts: [:], calendar: calendar, start: day(2026, 6, 1)), 13)
        // Slipped Jun 10 -> clean Jun 11–13 = 3.
        XCTAssertEqual(Streaks.cleanStreak(asOf: day(2026, 6, 13), counts: [day(2026, 6, 10): 1], calendar: calendar, start: day(2026, 6, 1)), 3)
        // Slipped today -> 0.
        XCTAssertEqual(Streaks.cleanStreak(asOf: day(2026, 6, 13), counts: [day(2026, 6, 13): 1], calendar: calendar, start: day(2026, 6, 1)), 0)
    }

    func testCleanRate() {
        // Jun 1–10 (10 days), slipped 2 -> 8/10 = 0.8.
        let counts = [day(2026, 6, 3): 1, day(2026, 6, 7): 1]
        XCTAssertEqual(Streaks.cleanRate(counts: counts, from: day(2026, 6, 1), asOf: day(2026, 6, 10), calendar: calendar), 0.8, accuracy: 0.0001)
    }

    func testLongestClean() {
        // Slips on Jun 4 and Jun 8 -> longest clean run is 3 (Jun 1–3 or Jun 5–7).
        let counts = [day(2026, 6, 4): 1, day(2026, 6, 8): 1]
        XCTAssertEqual(Streaks.longestClean(counts: counts, from: day(2026, 6, 1), asOf: day(2026, 6, 10), calendar: calendar), 3)
    }

    func testQuitGridCleanVsSlip() {
        let slipDay = day(2026, 6, 10)
        let grid = ContributionGridBuilder.buildQuit(
            start: day(2026, 6, 1), endingOn: day(2026, 6, 13), weeks: 4, counts: [slipDay: 1], calendar: calendar
        )
        let slip = grid.cells.first { calendar.isDate($0.date, inSameDayAs: slipDay) }
        XCTAssertEqual(slip?.isSlip, true)
        let clean = grid.cells.first { calendar.isDate($0.date, inSameDayAs: day(2026, 6, 9)) }
        XCTAssertEqual(clean?.isSlip, false)
        XCTAssertEqual(clean?.level, 4, "a clean day is filled")
    }
}
