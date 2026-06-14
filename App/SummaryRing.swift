import SwiftUI

// A Belora-style progress ring: shows how many habits are done today as an animated arc
// (600ms ease-out fill, like the spec's ConfidenceRing). Calm, non-decorative motion.
struct SummaryRing: View {
    let done: Int
    let total: Int

    @State private var animatedFraction: Double = 0

    private var fraction: Double {
        total == 0 ? 0 : Double(done) / Double(total)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.line1, lineWidth: 5)
            Circle()
                .trim(from: 0, to: animatedFraction)
                .stroke(Color.brand, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))   // start the arc at 12 o'clock
            Text("\(done)/\(total)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.fg1)
        }
        .frame(width: 52, height: 52)
        .onAppear { animate(to: fraction) }
        .onChange(of: fraction) { _, new in animate(to: new) }
    }

    private func animate(to value: Double) {
        withAnimation(.easeOut(duration: 0.6)) { animatedFraction = value }
    }
}
