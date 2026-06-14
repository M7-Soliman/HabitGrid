import WidgetKit
import SwiftUI

// The extension's entry point — bundles the widget(s) this extension provides.
@main
struct HabitWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitWidget()
    }
}
