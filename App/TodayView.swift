import SwiftUI
import SwiftData

// The main screen: a calm summary header (progress ring) over a list of habit cards.
// Add via +, edit/delete by swiping. Styled to the Belora design language.
struct TodayView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \HabitModel.createdAt) private var habits: [HabitModel]
    @AppStorage("didSeedHabits") private var didSeed = false

    @State private var showingAdd = false
    @State private var editingHabit: HabitModel?
    @State private var selectedHabit: HabitModel?   // tapped card -> detail screen

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                summaryHeader
                if habits.isEmpty {
                    emptyState
                } else {
                    habitList
                }
            }
            .background(Color.appBg)
            .navigationDestination(item: $selectedHabit) { habit in
                HabitDetailView(habit: habit)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                    .tint(Color.brand)
                }
            }
            .sheet(isPresented: $showingAdd) { HabitEditorView(habit: nil) }
            .sheet(item: $editingHabit) { habit in HabitEditorView(habit: habit) }
        }
        .tint(Color.brand)
        .onAppear(perform: seedIfNeeded)
    }

    // Progress ring + "N of M done today" + date.
    private var summaryHeader: some View {
        HStack(spacing: 16) {
            SummaryRing(done: doneTodayCount, total: habits.count)
            VStack(alignment: .leading, spacing: 3) {
                Text(allDone ? "All done today" : "\(doneTodayCount) of \(habits.count) done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.fg1)
                Text(dateString.uppercased())
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(0.5)
                    .foregroundStyle(Color.fg4)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 16)
    }

    private var habitList: some View {
        List {
            ForEach(habits) { habit in
                HabitCardView(habit: habit)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedHabit = habit }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing) {
                        // Belora: no red. Delete uses a muted tone; the icon carries meaning.
                        Button(role: .destructive) {
                            context.delete(habit)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(Color.fg3)
                        Button {
                            editingHabit = habit
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(Color.brand)
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Habits", systemImage: "square.grid.3x3.fill")
        } description: {
            Text("Add a habit to start building your grid.")
        } actions: {
            Button("Add Habit") { showingAdd = true }
                .buttonStyle(.borderedProminent)
                .tint(Color.brand)
        }
    }

    // MARK: - Derived

    private var doneTodayCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return habits.filter { habit in
            habit.completions.contains { calendar.isDate($0.date, inSameDayAs: today) }
        }.count
    }

    private var allDone: Bool { !habits.isEmpty && doneTodayCount == habits.count }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    private func seedIfNeeded() {
        guard !didSeed, habits.isEmpty else { return }
        let samples = [
            ("Gym", "#818CF8"),
            ("Read", "#22D3EE"),
            ("Meditate", "#A78BFA"),
        ]
        for (name, color) in samples {
            context.insert(HabitModel(name: name, colorHex: color))
        }
        didSeed = true
    }
}
