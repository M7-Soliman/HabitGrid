import SwiftUI
import SwiftData
import HabitCore

// A single habit as a Belora-style card: shape defined by a 1px border (no shadow),
// mono streak count, calm typography. Header + flame streak + contribution grid.
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
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.appCard)
        )
        // Border defines the card (Belora: shape from border, not elevation).
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.cardBorder, lineWidth: 1)
        )
    }

    private var color: Color { Color(hex: habit.colorHex) }

    // Color dot, habit name, and the tap-to-log button for today.
    private var header: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
            Text(habit.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.fg1)
            Spacer()
            Button {
                Haptics.tap()
                toggleToday()
            } label: {
                Image(systemName: isDoneToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isDoneToday ? color : Color.fg4)
                    // A meaningful bounce on the human action of logging.
                    .symbolEffect(.bounce, value: isDoneToday)
            }
            .buttonStyle(.plain)
        }
    }

    // Flame + current streak (mono count) with a small uppercase label, Belora-style.
    private var streakBadge: some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(currentStreak > 0 ? color : Color.fg4)
                Text("\(currentStreak)")
                    .font(.system(size: 19, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.fg1)
            }
            Text("DAY STREAK")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(0.4)
                .foregroundStyle(Color.fg4)
        }
        .frame(minWidth: 60)
    }

    // --- Derive HabitCore inputs from this habit's stored completions. ---

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
