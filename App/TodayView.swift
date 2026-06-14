import SwiftUI
import SwiftData
import HabitCore

// The main screen: a list of habits. Each row shows the habit's name, a tap-to-log button
// for today, its current streak, and its contribution grid.
struct TodayView: View {
    @Environment(\.modelContext) private var context

    // @Query pulls habits straight from SwiftData and auto-refreshes the view on any change.
    @Query(sort: \HabitModel.createdAt) private var habits: [HabitModel]

    var body: some View {
        NavigationStack {
            List {
                ForEach(habits) { habit in
                    HabitRow(habit: habit)
                }
            }
            .navigationTitle("Today")
        }
        // On first ever launch there are no habits, so drop in a few to play with.
        .onAppear(perform: seedIfEmpty)
    }

    private func seedIfEmpty() {
        guard habits.isEmpty else { return }
        let samples = [
            ("Gym", "#39D353"),
            ("Read", "#4F9DDE"),
            ("Meditate", "#B660E0"),
        ]
        for (name, color) in samples {
            context.insert(HabitModel(name: name, colorHex: color))
        }
    }
}

// One habit's row: header (color dot + name + today's toggle) and, below, streak + grid.
struct HabitRow: View {
    @Environment(\.modelContext) private var context
    let habit: HabitModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Header line: color dot, name, and the tap-to-log button for today.
            HStack {
                Circle()
                    .fill(Color(hex: habit.colorHex))
                    .frame(width: 12, height: 12)
                Text(habit.name)
                    .font(.headline)
                Spacer()
                Button(action: toggleToday) {
                    Image(systemName: isDoneToday ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(Color(hex: habit.colorHex))
                }
                .buttonStyle(.plain)
            }

            // Streak number on the left, grid on the right.
            HStack(alignment: .center, spacing: 14) {
                VStack(spacing: 0) {
                    Text("\(currentStreak)")
                        .font(.title2.bold())
                        .monospacedDigit()
                    Text("streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                ContributionGridView(grid: grid, baseColor: Color(hex: habit.colorHex))
            }
        }
        .padding(.vertical, 6)
    }

    // --- Derived data: turn this habit's completions into the shapes HabitCore wants. ---

    // Bucket completions into per-day counts (the input HabitCore's algorithms expect).
    private var dailyCounts: [Date: Int] {
        let calendar = Calendar.current
        var counts: [Date: Int] = [:]
        for completion in habit.completions {
            counts[calendar.startOfDay(for: completion.date), default: 0] += 1
        }
        return counts
    }

    private var grid: ContributionGrid {
        ContributionGridBuilder.build(endingOn: Date(), weeks: 18, counts: dailyCounts)
    }

    private var currentStreak: Int {
        Streaks.current(counts: dailyCounts)
    }

    // Has this habit been logged today already?
    private var isDoneToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return habit.completions.contains { calendar.isDate($0.date, inSameDayAs: today) }
    }

    // Tapping toggles today: add a completion if none today, else remove today's.
    private func toggleToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let existing = habit.completions.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            context.delete(existing)
        } else {
            context.insert(CompletionModel(date: Date(), habit: habit))
        }
    }
}
