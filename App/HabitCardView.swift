import SwiftUI
import SwiftData
import HabitCore

// A single habit, drawn as a rounded card: header (color dot + name + today's toggle),
// then a flame streak badge on the left and the contribution grid on the right.
struct HabitCardView: View {
    @Environment(\.modelContext) private var context
    let habit: HabitModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            HStack(alignment: .center, spacing: 16) {
                streakBadge
                ContributionGridView(grid: grid, baseColor: color)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        )
        // Hairline border for definition (mostly noticeable in dark mode).
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    private var color: Color { Color(hex: habit.colorHex) }

    // Color dot, habit name, and the tap-to-log button for today.
    private var header: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(habit.name)
                .font(.headline)
            Spacer()
            Button(action: toggleToday) {
                Image(systemName: isDoneToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isDoneToday ? color : Color.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // Flame + current streak, label underneath.
    private var streakBadge: some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.subheadline)
                    .foregroundStyle(currentStreak > 0 ? color : Color.secondary)
                Text("\(currentStreak)")
                    .font(.title3.bold())
                    .monospacedDigit()
            }
            Text("day streak")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 58)
    }

    // --- Derive HabitCore inputs from this habit's stored completions. ---

    // Per-day completion counts (what the grid + streak algorithms expect).
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

    private var isDoneToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return habit.completions.contains { calendar.isDate($0.date, inSameDayAs: today) }
    }

    // Toggle today's completion on/off.
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
