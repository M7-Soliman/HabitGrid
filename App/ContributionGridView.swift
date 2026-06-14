import SwiftUI
import HabitCore

// Draws a GitHub-style heatmap from a HabitCore `ContributionGrid`.
// The grid is "columns of weeks"; each column is 7 stacked day-squares (Sun..Sat).
struct ContributionGridView: View {
    let grid: ContributionGrid     // the laid-out weeks x days
    let baseColor: Color           // this habit's color; intensity scales its opacity

    // Visual constants: square size and the gap between squares.
    private let cellSize: CGFloat = 11
    private let spacing: CGFloat = 3

    var body: some View {
        // A year of columns won't fit on a phone, so allow horizontal scrolling.
        ScrollView(.horizontal, showsIndicators: false) {

            // One horizontal row of week-columns, oldest on the left.
            HStack(alignment: .top, spacing: spacing) {

                // ForEach needs stable ids; the column index is fine here.
                ForEach(Array(grid.weeks.enumerated()), id: \.offset) { _, week in

                    // Each column: 7 vertical day-slots.
                    VStack(spacing: spacing) {
                        ForEach(0..<7, id: \.self) { row in
                            squareView(for: week[row])
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // One day square. A `nil` slot is a day outside the range (drawn as an empty cell).
    private func squareView(for day: GridCell?) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(fillColor(for: day))
            .frame(width: cellSize, height: cellSize)
    }

    // Level 0 / empty -> faint gray. Levels 1–4 ramp the habit color from light to full.
    private func fillColor(for day: GridCell?) -> Color {
        guard let day, day.level > 0 else {
            return Color.gray.opacity(0.15)
        }
        let opacityByLevel = [0.0, 0.4, 0.6, 0.8, 1.0]   // index by level 1...4
        return baseColor.opacity(opacityByLevel[min(day.level, 4)])
    }
}
