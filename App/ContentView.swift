import SwiftUI
import HabitCore   // our pure-logic package: ContributionGrid, builder, etc.

// The first screen. For now it renders a contribution grid from *sample* data so we can
// confirm the whole pipeline works (app -> HabitCore -> a grid on screen). Real habits and
// storage come in the next milestone; this view will then read from SwiftData instead.
struct ContentView: View {

    // Build a fake ~6 months of random completions ending today, then turn it into a grid.
    // Computed once when the view is created.
    private let grid: ContributionGrid = {
        var counts: [Date: Int] = [:]
        let calendar = Calendar.current

        // Walk back ~180 days; on a coin flip, mark that day done 1–5 times.
        for dayOffset in 0..<180 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            if Bool.random() {
                counts[calendar.startOfDay(for: day)] = Int.random(in: 1...5)
            }
        }

        // Lay those counts out as 26 week-columns ending on today's week.
        return ContributionGridBuilder.build(endingOn: Date(), weeks: 26, counts: counts)
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HabitGrid")
                .font(.largeTitle.bold())

            Text("Sample grid · random data")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // The grid itself, tinted GitHub-green for now.
            ContributionGridView(grid: grid, baseColor: Color(hex: "#39D353"))

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
