import AppIntents
import SwiftData

// The thing a user picks when configuring the widget: which habit to show.
struct HabitEntity: AppEntity, Identifiable {
    let id: UUID
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Habit" }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }

    static var defaultQuery = HabitEntityQuery()
}

// Supplies the list of habits to the widget's "Edit Widget" picker, reading the shared store.
struct HabitEntityQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [HabitEntity.ID]) async throws -> [HabitEntity] {
        try allHabits().filter { identifiers.contains($0.id) }
    }

    @MainActor
    func suggestedEntities() async throws -> [HabitEntity] {
        try allHabits()
    }

    @MainActor
    private func allHabits() throws -> [HabitEntity] {
        let context = ModelContext(HabitStore.container)
        let habits = try context.fetch(FetchDescriptor<HabitModel>(sortBy: [SortDescriptor(\.createdAt)]))
        return habits.map { HabitEntity(id: $0.id, name: $0.name) }
    }
}

// The widget's configuration: a single "Habit" parameter, so each placed instance can show
// a different habit (long-press → Edit Widget → pick one).
struct SelectHabitIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Select Habit" }
    static var description: IntentDescription { IntentDescription("Choose which habit this widget shows.") }

    @Parameter(title: "Habit")
    var habit: HabitEntity?

    init() {}
}
