import XCTest
@testable import HabitCore

final class ContributionGridTests: XCTestCase {

    /// Deterministic calendar: UTC, weeks start on Sunday. Avoids machine-locale flakiness.
    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.firstWeekday = 1 // Sunday
        return cal
    }()

    /// Builds a UTC date at midnight for the given Y-M-D.
    private func day(_ year: Int, _ month: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: d))!
    }

    func testGridHasRequestedColumnsAndSevenRows() {
        let grid = ContributionGridBuilder.build(
            endingOn: day(2026, 6, 13),
            weeks: 53,
            counts: [:],
            calendar: calendar
        )
        XCTAssertEqual(grid.weeks.count, 53)
        XCTAssertTrue(grid.weeks.allSatisfy { $0.count == 7 })
    }

    func testCountOnADayLandsInThatCell() {
        let target = day(2026, 6, 10) // a Wednesday
        let grid = ContributionGridBuilder.build(
            endingOn: day(2026, 6, 13),
            weeks: 4,
            counts: [target: 3],
            calendar: calendar
        )
        let hit = grid.cells.first { calendar.isDate($0.date, inSameDayAs: target) }
        XCTAssertEqual(hit?.count, 3)
        XCTAssertEqual(hit?.level, 2, "count 3 falls in the 2..<4 bucket -> level 2")
    }

    func testFutureDaysInFinalWeekAreNil() {
        // end is a Wednesday; Thu–Sat of that week are in the future and must be blank.
        let grid = ContributionGridBuilder.build(
            endingOn: day(2026, 6, 10), // Wednesday
            weeks: 1,
            counts: [:],
            calendar: calendar
        )
        let lastWeek = grid.weeks[0]
        // Sun..Wed present (rows 0–3), Thu..Sat nil (rows 4–6).
        XCTAssertNotNil(lastWeek[3])
        XCTAssertNil(lastWeek[4])
        XCTAssertNil(lastWeek[6])
    }

    func testFirstWeekdayAlignment() {
        // Row 0 of every column should be the calendar's firstWeekday (Sunday here).
        let grid = ContributionGridBuilder.build(
            endingOn: day(2026, 6, 13),
            weeks: 2,
            counts: [:],
            calendar: calendar
        )
        for week in grid.weeks {
            if let first = week[0] {
                let weekday = calendar.component(.weekday, from: first.date)
                XCTAssertEqual(weekday, calendar.firstWeekday)
            }
        }
    }

    func testLevelThresholds() {
        let t = [1, 2, 4, 6]
        XCTAssertEqual(ContributionGridBuilder.level(for: 0, thresholds: t), 0)
        XCTAssertEqual(ContributionGridBuilder.level(for: 1, thresholds: t), 1)
        XCTAssertEqual(ContributionGridBuilder.level(for: 3, thresholds: t), 2)
        XCTAssertEqual(ContributionGridBuilder.level(for: 5, thresholds: t), 3)
        XCTAssertEqual(ContributionGridBuilder.level(for: 99, thresholds: t), 4)
    }

    func testDailyCountsAggregatesCompletions() {
        let habit = UUID()
        let other = UUID()
        let completions = [
            Completion(habitID: habit, date: day(2026, 6, 10)),
            Completion(habitID: habit, date: calendar.date(byAdding: .hour, value: 9, to: day(2026, 6, 10))!),
            Completion(habitID: other, date: day(2026, 6, 10)),
        ]
        let counts = completions.dailyCounts(for: habit, calendar: calendar)
        XCTAssertEqual(counts[day(2026, 6, 10)], 2, "two ticks same day for this habit, ignore other habit")
    }
}
