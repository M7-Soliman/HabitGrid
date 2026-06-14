import SwiftUI
import SwiftData
import HabitCore

// Pushed when a habit card is tapped: a full-year grid plus stats (current & longest
// streak, totals). Styled to the Belora language — stat cells with mono counts.
struct HabitDetailView: View {
    let habit: HabitModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                statsRow
                section(sectionTitle) {
                    ContributionGridView(grid: yearGrid, baseColor: color)
                    legend
                }
            }
            .padding(20)
        }
        .background(Color.appBg)
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private var color: Color { Color(hex: habit.colorHex) }
    private var isQuit: Bool { habit.kind == .quit }

    private var sectionTitle: String {
        if isQuit { return "DAYS CLEAN" }
        return habit.dailyTarget > 1 ? "ACTIVITY · GOAL \(habit.dailyTarget)×/DAY" : "ACTIVITY"
    }

    // Stat cells differ by kind: build = streak/longest/total/%; quit = clean/best/slips/rate.
    private var statsRow: some View {
        HStack(spacing: 10) {
            if isQuit {
                statCell("\(Streaks.cleanStreak(counts: dailyCounts, start: habit.createdAt))", "CLEAN")
                statCell("\(Streaks.longestClean(counts: dailyCounts, from: habit.createdAt))", "BEST")
                statCell("\(habit.completionsList.count)", "SLIPS")
                statCell("\(consistencyPercent)%", "RATE")
            } else {
                statCell("\(Streaks.current(counts: dailyCounts, metThreshold: habit.dailyTarget))", "STREAK")
                statCell("\(Streaks.longest(counts: dailyCounts, metThreshold: habit.dailyTarget))", "LONGEST")
                statCell("\(habit.completionsList.count)", "TOTAL")
                statCell("\(consistencyPercent)%", "OVERALL")
            }
        }
    }

    // Build: % of days since first log that met the goal. Quit: % of days clean since created.
    private var consistencyPercent: Int {
        let calendar = Calendar.current
        if isQuit {
            return Int((Streaks.cleanRate(counts: dailyCounts, from: habit.createdAt) * 100).rounded())
        }
        guard let firstLogged = habit.completionsList.map({ calendar.startOfDay(for: $0.date) }).min() else {
            return 0   // never logged
        }
        let today = calendar.startOfDay(for: Date())
        let days = (calendar.dateComponents([.day], from: firstLogged, to: today).day ?? 0) + 1
        let rate = Streaks.metRate(counts: dailyCounts, lastDays: max(days, 1), metThreshold: habit.dailyTarget)
        return Int((rate * 100).rounded())
    }

    private func statCell(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.fg1)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(0.4)
                .foregroundStyle(Color.fg4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.appCard))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: 1))
    }

    // A SectionH-style label + its content.
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .tracking(0.6)
                .foregroundStyle(Color.fg4)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.appCard))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: 1))
    }

    // Shading key — Less→More for build habits, Clean/Slip for quit habits.
    @ViewBuilder private var legend: some View {
        if isQuit {
            HStack(spacing: 10) {
                legendItem(color, "CLEAN")
                legendItem(Color.slip, "SLIP")
            }
        } else {
            HStack(spacing: 5) {
                Text("LESS")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.fg4)
                ForEach(0..<5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(level == 0 ? Color.gridEmpty : color.opacity([0, 0.35, 0.55, 0.78, 1.0][level]))
                        .frame(width: 10, height: 10)
                }
                Text("MORE")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.fg4)
            }
        }
    }

    private func legendItem(_ swatch: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2.5, style: .continuous).fill(swatch).frame(width: 10, height: 10)
            Text(label).font(.system(size: 8, weight: .medium, design: .monospaced)).foregroundStyle(Color.fg4)
        }
    }

    // MARK: - Derived

    private var dailyCounts: [Date: Int] {
        let calendar = Calendar.current
        var counts: [Date: Int] = [:]
        for completion in habit.completionsList {
            counts[calendar.startOfDay(for: completion.date), default: 0] += 1
        }
        return counts
    }

    // A full year (53 week-columns): build shades by goal; quit fills clean days + flags slips.
    private var yearGrid: ContributionGrid {
        if isQuit {
            return ContributionGridBuilder.buildQuit(start: habit.createdAt, endingOn: Date(), weeks: 53, counts: dailyCounts)
        }
        return ContributionGridBuilder.build(endingOn: Date(), weeks: 53, counts: dailyCounts, target: habit.dailyTarget)
    }

    private var thisYearCount: Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        return habit.completionsList.filter { calendar.component(.year, from: $0.date) == year }.count
    }
}
