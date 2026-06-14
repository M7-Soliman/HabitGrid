import SwiftUI
import SwiftData

// A sheet for creating a new habit or editing an existing one (name + color).
// When `habit` is nil we're adding; otherwise we're editing that habit.
struct HabitEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let habit: HabitModel?

    @State private var name = ""
    @State private var colorHex = HabitPalette.default

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Gym", text: $name)
                }
                Section("Color") {
                    colorPalette
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
                    colorHex = habit.colorHex
                }
            }
        }
    }

    // A grid of color swatches; the selected one gets a ring.
    private var colorPalette: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 14) {
            ForEach(HabitPalette.colors, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primary, lineWidth: colorHex == hex ? 3 : 0)
                            .padding(-3)
                    )
                    .onTapGesture { colorHex = hex }
            }
        }
        .padding(.vertical, 6)
    }

    // Create or update, then close the sheet.
    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let habit {
            habit.name = trimmed
            habit.colorHex = colorHex
        } else {
            context.insert(HabitModel(name: trimmed, colorHex: colorHex))
        }
        dismiss()
    }
}
