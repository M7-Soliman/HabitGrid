import SwiftUI
import SwiftData
import WidgetKit
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
            // "−" to remove one of today's logs; only shown when there's something to remove.
            if todayCount > 0 {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.fg3)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color.line2, lineWidth: 1.5))
                    .contentShape(Circle())
                    .highPriorityGesture(TapGesture().onEnded { Haptics.tap(); decrement() })
            }
            LogButton(
                count: todayCount,
                target: habit.dailyTarget,
                color: color,
                onIncrement: increment
            )
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
        for completion in habit.completionsList {
            counts[calendar.startOfDay(for: completion.date), default: 0] += 1
        }
        return counts
    }

    private var grid: ContributionGrid {
        ContributionGridBuilder.build(endingOn: Date(), weeks: 18, counts: dailyCounts, target: habit.dailyTarget)
    }

    private var currentStreak: Int {
        Streaks.current(counts: dailyCounts, metThreshold: habit.dailyTarget)
    }

    // How many times the habit was logged today.
    private var todayCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return habit.completionsList.filter { calendar.isDate($0.date, inSameDayAs: today) }.count
    }

    // +1: log another occurrence today.
    private func increment() {
        context.insert(CompletionModel(date: Date(), habit: habit))
        WidgetCenter.shared.reloadAllTimelines()   // refresh the widget right away
    }

    // −1: remove one of today's occurrences (if any).
    private func decrement() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let existing = habit.completionsList.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            context.delete(existing)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
