import SwiftUI
import HabitCore

// Draws a GitHub-style heatmap from a HabitCore `ContributionGrid`, with month labels
// across the top and today's cell ringed. The grid is "columns of weeks"; each column
// is 7 stacked day-squares (Sun..Sat).
struct ContributionGridView: View {
    let grid: ContributionGrid     // the laid-out weeks x days
    let baseColor: Color           // this habit's color; intensity scales its opacity
    var scrollable: Bool = true    // off for widgets (they can't scroll)
    var showMonthLabels: Bool = true
    var cellSize: CGFloat = 11     // smaller in widgets so 7 rows fit
    var spacing: CGFloat = 3

    private let today = Calendar.current.startOfDay(for: Date())

    var body: some View {
        if scrollable {
            // Overflowing columns scroll horizontally, anchored so recent weeks show first.
            ScrollView(.horizontal, showsIndicators: false) {
                gridStack
            }
            .defaultScrollAnchor(.trailing)
        } else {
            gridStack
        }
    }

    private var gridStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showMonthLabels { monthHeader }
            weekColumns
        }
        .padding(.vertical, 2)
    }

    // One column per week, oldest on the left; each column is 7 day-squares.
    private var weekColumns: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(Array(grid.weeks.enumerated()), id: \.offset) { _, week in
                VStack(spacing: spacing) {
                    ForEach(0..<7, id: \.self) { row in
                        squareView(for: week[row])
                    }
                }
            }
        }
    }

    // One day square. `nil` = a day outside the range (faint empty cell). Today is ringed.
    private func squareView(for day: GridCell?) -> some View {
        let isToday = day.map { Calendar.current.isDate($0.date, inSameDayAs: today) } ?? false
        let level = day?.level ?? 0
        return ZStack {
            // Empty backing cell — adaptive token (calm, near-monochrome).
            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .fill(Color.gridEmpty)
            // Habit color on top, stronger at higher levels. Compositing OVER the empty
            // backing (rather than the card) keeps low levels readable in both modes.
            if level > 0 {
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(baseColor.opacity(intensity(forLevel: level)))
            }
        }
        .frame(width: cellSize, height: cellSize)
        .overlay(
            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .strokeBorder(isToday ? Color.brand : .clear, lineWidth: 1.2)
        )
    }

    // How strongly to tint each level (1...4) of the habit color.
    private func intensity(forLevel level: Int) -> Double {
        [0.0, 0.35, 0.55, 0.78, 1.0][min(level, 4)]
    }

    // --- Month labels across the top, aligned to the columns of each month. ---

    private var monthHeader: some View {
        HStack(spacing: spacing) {
            ForEach(monthSegments()) { segment in
                Text(segment.label.uppercased())
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .tracking(0.3)
                    .foregroundStyle(Color.fg4)
                    .frame(width: width(forColumns: segment.columnCount), alignment: .leading)
            }
        }
    }

    // Width that exactly spans `n` grid columns (so a label sits over its month).
    private func width(forColumns n: Int) -> CGFloat {
        CGFloat(n) * cellSize + CGFloat(max(n - 1, 0)) * spacing
    }

    private struct MonthSegment: Identifiable {
        let id = UUID()
        let label: String
        let columnCount: Int
    }

    // Group consecutive week-columns by month; label a group only if it's wide enough
    // for the month abbreviation to fit (avoids clipped "J" stubs).
    private func monthSegments() -> [MonthSegment] {
        let calendar = Calendar.current
        let symbols = calendar.shortMonthSymbols

        // Representative month for each column (from its first real cell).
        let monthsPerColumn: [Int?] = grid.weeks.map { week in
            guard let date = week.compactMap({ $0?.date }).first else { return nil }
            return calendar.component(.month, from: date)
        }

        var segments: [MonthSegment] = []
        var index = 0
        while index < monthsPerColumn.count {
            let month = monthsPerColumn[index]
            var count = 1
            while index + count < monthsPerColumn.count && monthsPerColumn[index + count] == month {
                count += 1
            }
            let label = (month != nil && count >= 3) ? symbols[month! - 1] : ""
            segments.append(MonthSegment(label: label, columnCount: count))
            index += count
        }
        return segments
    }
}
