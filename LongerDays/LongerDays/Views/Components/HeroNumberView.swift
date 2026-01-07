import SwiftUI

struct HeroNumberView: View {
    let changeSeconds: Int
    let isGainingDaylight: Bool
    let solsticeLabel: String  // e.g., "Dec 21" or "Jun 21"

    var body: some View {
        VStack(spacing: 4) {
            Text(formattedChange)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(isGainingDaylight ? Theme.accent : Theme.negative)

            Text("since \(solsticeLabel)")
                .font(.subheadline)
                .foregroundColor(Theme.secondaryText)
        }
    }

    private var formattedChange: String {
        let absSeconds = abs(changeSeconds)
        let hours = absSeconds / 3600
        let minutes = (absSeconds % 3600) / 60

        let sign = changeSeconds >= 0 ? "+" : "-"

        if hours > 0 {
            return "\(sign)\(hours)h \(minutes)m"
        } else {
            return "\(sign)\(minutes)m"
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()

        VStack(spacing: 40) {
            HeroNumberView(
                changeSeconds: 2820,  // 47 minutes
                isGainingDaylight: true,
                solsticeLabel: "Dec 21"
            )

            HeroNumberView(
                changeSeconds: 4500,  // 1h 15m
                isGainingDaylight: true,
                solsticeLabel: "Dec 21"
            )

            HeroNumberView(
                changeSeconds: -1380,  // -23 minutes
                isGainingDaylight: false,
                solsticeLabel: "Jun 21"
            )
        }
    }
}
