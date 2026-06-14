import SwiftUI
import SwiftData

// The app's entry point. `@main` tells the OS this struct boots the app.
@main
struct HabitGridApp: App {
    var body: some Scene {
        WindowGroup {
            TodayView()
        }
        // Spin up the on-device SwiftData store for our models. This local container
        // is also where we'd later turn on iCloud/CloudKit sync.
        .modelContainer(for: [HabitModel.self, CompletionModel.self])
    }
}
