import SwiftUI
import HabitCore

// Draws a GitHub-style heatmap from a HabitCore `ContributionGrid`, with month labels
// across the top and today's cell ringed. The grid is "columns of weeks"; each column
// is 7 stacked day-squares (Sun..Sat).
struct ContributionGridView: View {
    let grid: ContributionGrid     // the laid-out weeks x days
    let baseColor: Color           // this habit's color; intensity scales its opacity

    private let cellSize: CGFloat = 11
    private let spacing: CGFloat = 3
    private let today = Calendar.current.startOfDay(for: Date())

    var body: some View {
        // A few months of columns may overflow the card, so scroll horizontally.
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 4) {
                monthHeader
                weekColumns
            }
            .padding(.vertical, 2)
        }
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
        return RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(fillColor(for: day))
            .frame(width: cellSize, height: cellSize)
            .overlay(
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .strokeBorder(isToday ? Color.primary.opacity(0.55) : .clear, lineWidth: 1.2)
            )
    }

    // Empty/level 0 -> faint gray. Levels 1–4 ramp the habit color from light to full.
    private func fillColor(for day: GridCell?) -> Color {
        guard let day, day.level > 0 else {
            return Color(.systemGray5)
        }
        let opacityByLevel = [0.0, 0.4, 0.6, 0.8, 1.0]   // index by level 1...4
        return baseColor.opacity(opacityByLevel[min(day.level, 4)])
    }

    // --- Month labels across the top, aligned to the columns of each month. ---

    private var monthHeader: some View {
        HStack(spacing: spacing) {
            ForEach(monthSegments()) { segment in
                Text(segment.label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
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
