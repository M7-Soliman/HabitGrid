import SwiftData

// The single SwiftData store, kept in a shared App Group container so BOTH the app and
// the widget extension read/write the same database. Without the group container the
// widget (a separate process) couldn't see the app's data.
enum HabitStore {
    static let appGroupID = "group.com.m7soliman.HabitGrid"

    static let container: ModelContainer = {
        let configuration = ModelConfiguration(groupContainer: .identifier(appGroupID))
        do {
            return try ModelContainer(for: HabitModel.self, CompletionModel.self, configurations: configuration)
        } catch {
            fatalError("Could not create the shared ModelContainer: \(error)")
        }
    }()
}
