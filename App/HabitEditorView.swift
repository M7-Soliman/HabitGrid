import SwiftUI
import SwiftData

// A sheet for creating a new habit or editing an existing one (name + color).
// When `habit` is nil we're adding; otherwise we're editing that habit.
struct HabitEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let habit: HabitModel?

    @State private var name = ""
    @State private var color = Color(hex: HabitPalette.default)
    @State private var target = 1

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Gym", text: $name)
                }
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
        } else {
            context.insert(HabitModel(name: trimmed, colorHex: hex, dailyTarget: target))
        }
        dismiss()
    }
}
