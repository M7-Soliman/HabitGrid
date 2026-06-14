import SwiftUI
import SwiftData

// The app's entry point. `@main` tells the OS this struct boots the app.
@main
struct HabitGridApp: App {
    var body: some Scene {
        WindowGroup {
            TodayView()
        }
        // Use the shared App Group store so the widget reads the same data.
        .modelContainer(HabitStore.container)
    }
}
