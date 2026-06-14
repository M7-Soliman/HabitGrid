import WidgetKit
import SwiftUI
import SwiftData
import HabitCore

// One timeline entry = a snapshot of the chosen habit's grid + streak.
struct HabitEntry: TimelineEntry, Sendable {
    let date: Date
    let habitID: UUID?
    let habitName: String?
    let colorHex: String
    let target: Int
    let streak: Int
    let grid: ContributionGrid
}

// Reads the shared store and builds entries for the configured habit.
struct HabitProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: .now, habitID: nil, habitName: "Habit", colorHex: "#A8C5F5", target: 1, streak: 0,
                   grid: ContributionGridBuilder.build(endingOn: .now, weeks: weeks(for: context.family), counts: [:]))
    }

    func snapshot(for configuration: SelectHabitIntent, in context: Context) async -> HabitEntry {
        await makeEntry(for: configuration, family: context.family)
    }

    func timeline(for configuration: SelectHabitIntent, in context: Context) async -> Timeline<HabitEntry> {
        let entry = await makeEntry(for: configuration, family: context.family)
        // Refresh just after midnight so "today" rolls over.
        let refresh = Calendar.current.nextDate(after: .now, matching: DateComponents(hour: 0, minute: 5),
                                                matchingPolicy: .nextTime) ?? .now.addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    // How many week-columns fit each widget size.
    private func weeks(for family: WidgetFamily) -> Int {
        family == .systemMedium ? 20 : 12
    }

    @MainActor
    private func makeEntry(for configuration: SelectHabitIntent, family: WidgetFamily) -> HabitEntry {
        let context = ModelContext(HabitStore.container)
        let weekCount = weeks(for: family)

        // The chosen habit, or the first one if unset.
        var habit: HabitModel?
        if let id = configuration.habit?.id {
            habit = try? context.fetch(FetchDescriptor<HabitModel>(predicate: #Predicate { $0.id == id })).first
        }
        if habit == nil {
            habit = try? context.fetch(FetchDescriptor<HabitModel>(sortBy: [SortDescriptor(\.createdAt)])).first
        }

        guard let habit else {
            return HabitEntry(date: .now, habitID: nil, habitName: nil, colorHex: "#A8C5F5", target: 1, streak: 0,
                              grid: ContributionGridBuilder.build(endingOn: .now, weeks: weekCount, counts: [:]))
        }

        let calendar = Calendar.current
        var counts: [Date: Int] = [:]
        for completion in habit.completions {
            counts[calendar.startOfDay(for: completion.date), default: 0] += 1
        }
        let grid = ContributionGridBuilder.build(endingOn: .now, weeks: weekCount, counts: counts, target: habit.dailyTarget)
        let streak = Streaks.current(counts: counts, metThreshold: habit.dailyTarget)

        return HabitEntry(date: .now, habitID: habit.id, habitName: habit.name, colorHex: habit.colorHex,
                          target: habit.dailyTarget, streak: streak, grid: grid)
    }
}

struct HabitWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HabitEntry

    private var isMedium: Bool { family == .systemMedium }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(Color(hex: entry.colorHex)).frame(width: 8, height: 8)
                Text(entry.habitName ?? "Pick a habit")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.fg1)
                    .lineLimit(1)
                Spacer()
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(entry.streak > 0 ? Color(hex: entry.colorHex) : Color.fg4)
                    Text("\(entry.streak)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.fg1)
                }
            }
            ContributionGridView(
                grid: entry.grid,
                baseColor: Color(hex: entry.colorHex),
                scrollable: false,
                showMonthLabels: isMedium,
                cellSize: isMedium ? 11 : 9,    // smaller cells on the small widget so 7 rows fit
                spacing: isMedium ? 3 : 2
            )
            Spacer(minLength: 0)
        }
        .containerBackground(Color.appBg, for: .widget)
        // Tapping the widget deep-links into that habit's detail screen.
        .widgetURL(entry.habitID.map { URL(string: "habitgrid://habit/\($0.uuidString)")! })
    }
}

struct HabitWidget: Widget {
    let kind = "HabitWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectHabitIntent.self, provider: HabitProvider()) { entry in
            HabitWidgetView(entry: entry)
        }
        .configurationDisplayName("Habit Grid")
        .description("A habit's contribution grid and streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
