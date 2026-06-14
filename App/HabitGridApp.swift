import SwiftUI

// The app's entry point. `@main` tells the OS this struct boots the app.
// A SwiftUI `App` describes the window(s); here we show one window holding ContentView.
@main
struct HabitGridApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
