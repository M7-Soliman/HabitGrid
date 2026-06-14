import SwiftUI
import SwiftData

// The main screen: your habits as cards. Add via the + button, edit/delete by swiping.
struct TodayView: View {
    @Environment(\.modelContext) private var context

    // Pulls habits from SwiftData and auto-refreshes on any change.
    @Query(sort: \HabitModel.createdAt) private var habits: [HabitModel]

    // Seed the starter habits only once, ever (not every time the list goes empty).
    @AppStorage("didSeedHabits") private var didSeed = false

    @State private var showingAdd = false          // the "add" sheet
    @State private var editingHabit: HabitModel?   // the "edit" sheet (non-nil = open)

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    emptyState
                } else {
                    habitList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                HabitEditorView(habit: nil)
            }
            .sheet(item: $editingHabit) { habit in
                HabitEditorView(habit: habit)
            }
        }
        .onAppear(perform: seedIfNeeded)
    }

    // Scrollable list of habit cards with swipe-to-edit/delete.
    private var habitList: some View {
        List {
            ForEach(habits) { habit in
                HabitCardView(habit: habit)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            context.delete(habit)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            editingHabit = habit
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // Shown when there are no habits (e.g. after deleting them all).
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Habits", systemImage: "square.grid.3x3.fill")
        } description: {
            Text("Add a habit to start building your grid.")
        } actions: {
            Button("Add Habit") { showingAdd = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private func seedIfNeeded() {
        guard !didSeed, habits.isEmpty else { return }
        let samples = [
            ("Gym", "#39D353"),
            ("Read", "#4F9DDE"),
            ("Meditate", "#B660E0"),
        ]
        for (name, color) in samples {
            context.insert(HabitModel(name: name, colorHex: color))
        }
        didSeed = true
    }
}
