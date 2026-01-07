import SwiftUI

struct RecentHistoryView: View {
    let history: [(date: Date, changeSeconds: Int)]
    let isGainingDaylight: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Last 7 days")
                    .font(.headline)
                    .foregroundColor(Theme.primaryText)
                Spacer()
            }

            if history.isEmpty {
                Text("No history available")
                    .font(.subheadline)
                    .foregroundColor(Theme.secondaryText)
                    .padding(.vertical, 8)
            } else {
                HStack(spacing: 8) {
                    ForEach(history.indices, id: \.self) { index in
                        dayColumn(history[index])
                    }
                }
            }
        }
        .padding(20)
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }

    private func dayColumn(_ item: (date: Date, changeSeconds: Int)) -> some View {
        let minutes = item.changeSeconds / 60
        let sign = minutes >= 0 ? "+" : ""

        return VStack(spacing: 6) {
            Text("\(sign)\(minutes)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isGainingDaylight ? Theme.accent : Theme.negative)

            // Mini bar visualization
            RoundedRectangle(cornerRadius: 2)
                .fill(isGainingDaylight ? Theme.accent : Theme.negative)
                .frame(width: 24, height: barHeight(for: item.changeSeconds))

            Text(dayLabel(item.date))
                .font(.system(size: 10))
                .foregroundColor(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func barHeight(for changeSeconds: Int) -> CGFloat {
        // Normalize bar height based on change
        // Typical range: 30s to 180s per day
        let absSeconds = abs(changeSeconds)
        let normalized = min(1.0, Double(absSeconds) / 180.0)
        return 8 + CGFloat(normalized) * 24  // 8-32pt range
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"  // Mon, Tue, etc.
        let dayString = formatter.string(from: date)
        return String(dayString.prefix(1))  // Just first letter
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()

        VStack(spacing: 20) {
            RecentHistoryView(
                history: [
                    (Date().addingTimeInterval(-6 * 86400), 120),
                    (Date().addingTimeInterval(-5 * 86400), 125),
                    (Date().addingTimeInterval(-4 * 86400), 130),
                    (Date().addingTimeInterval(-3 * 86400), 135),
                    (Date().addingTimeInterval(-2 * 86400), 140),
                    (Date().addingTimeInterval(-1 * 86400), 138),
                    (Date(), 142)
                ],
                isGainingDaylight: true
            )

            RecentHistoryView(
                history: [],
                isGainingDaylight: true
            )
        }
        .padding()
    }
}
