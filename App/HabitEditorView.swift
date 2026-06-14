import SwiftUI
import SwiftData
import WidgetKit

// A sheet for creating a new habit or editing an existing one (name + color).
// When `habit` is nil we're adding; otherwise we're editing that habit.
struct HabitEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let habit: HabitModel?

    @State private var name = ""
    @State private var color = Color(hex: HabitPalette.default)
    @State private var target = 1
    @State private var kind: HabitKind = .build

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $kind) {
                        Text("Build").tag(HabitKind.build)
                        Text("Quit").tag(HabitKind.quit)
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text(kind == .build
                         ? "Log it each time you do it."
                         : "Track days clean — only log a slip when you slip up.")
                }
                Section("Name") {
                    TextField(kind == .build ? "e.g. Gym" : "e.g. No smoking", text: $name)
                }
                if kind == .build {
                    Section("Daily goal") {
                        Stepper(value: $target, in: 1...20) {
                            HStack {
                                Text("Target")
                                Spacer()
                                Text(target == 1 ? "Once a day" : "\(target)× a day")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Color") {
                    // Full system color picker — spectrum, sliders, and a hex field.
                    ColorPicker("Habit color", selection: $color, supportsOpacity: false)
                }
            }
            .navigationTitle(habit == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                // Pre-fill the fields when editing.
                if let habit {
                    name = habit.name
                    color = Color(hex: habit.colorHex)
                    target = habit.dailyTarget
                    kind = habit.kind
                }
            }
        }
    }

    // Create or update, then close the sheet.
    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let hex = color.hexString
        if let habit {
            habit.name = trimmed
            habit.colorHex = hex
            habit.dailyTarget = target
            habit.kind = kind
        } else {
            // Append new habits to the end of the manual order.
            let count = (try? context.fetchCount(FetchDescriptor<HabitModel>())) ?? 0
            context.insert(HabitModel(name: trimmed, colorHex: hex, dailyTarget: target, sortIndex: count, kind: kind))
        }
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
