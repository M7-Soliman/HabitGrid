import SwiftUI

// Per-habit logging control: a ring that fills toward the daily target.
// Tap = +1. Shows the count; fills solid + checks when the goal is met.
// (Removing one is a separate "−" button on the card — long-press is reserved for reordering.)
struct LogButton: View {
    let count: Int
    let target: Int
    let color: Color
    let onIncrement: () -> Void

    private var goal: Int { max(target, 1) }
    private var fraction: Double { min(1, Double(count) / Double(goal)) }
    private var met: Bool { count >= goal }

    var body: some View {
        ZStack {
            Circle().stroke(Color.line2, lineWidth: 2.5)
            if met {
                Circle().fill(color)
            } else {
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))   // start at 12 o'clock
            }
            label
        }
        .frame(width: 30, height: 30)
        .contentShape(Circle())
        // High priority so the tap wins over the card's open + the list's reorder gestures.
        .highPriorityGesture(TapGesture().onEnded { Haptics.tap(); onIncrement() })
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: count)
    }

    @ViewBuilder private var label: some View {
        if met && goal == 1 && count == 1 {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
        } else if count > 0 {
            Text("\(count)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(met ? .white : Color.fg1)
        }
        // count == 0 → empty circle, no label
    }
}

// For "quit" habits: clean is the default (a calm outline in the habit color); tapping logs a
// slip, turning it red with the slip count. Removing a slip uses the card's "−" button.
struct QuitButton: View {
    let slips: Int
    let color: Color
    let onSlip: () -> Void

    var body: some View {
        ZStack {
            if slips > 0 {
                Circle().fill(Color.slip)
                Text("\(slips)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            } else {
                Circle().strokeBorder(color.opacity(0.7), lineWidth: 2.5)
            }
        }
        .frame(width: 30, height: 30)
        .contentShape(Circle())
        .highPriorityGesture(TapGesture().onEnded { Haptics.tap(); onSlip() })
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: slips)
    }
}
