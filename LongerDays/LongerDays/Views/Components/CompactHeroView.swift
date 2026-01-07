import SwiftUI

struct CompactHeroView: View {
    let changeSeconds: Int
    let progress: Double  // 0.0 to 1.0
    let isGainingDaylight: Bool
    let daysSinceSolstice: Int

    private var endLabel: String {
        isGainingDaylight ? "summer solstice" : "winter solstice"
    }

    private var percentageText: String {
        "\(Int(progress * 100))%"
    }

    var body: some View {
        VStack(spacing: 16) {
            // Main number - the hero
            VStack(spacing: 2) {
                Text(formattedChange)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(isGainingDaylight ? Theme.accent : Theme.negative)

                Text("\(percentageText) of the way to \(endLabel)")
                    .font(.subheadline)
                    .foregroundColor(Theme.secondaryText)
            }

            // Progress bar (matching velocity style)
            GeometryReader { geometry in
                let width = geometry.size.width
                let progressWidth = width * progress

                ZStack(alignment: .leading) {
                    // Background track with outline
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.cardBackground.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )

                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: isGainingDaylight
                                    ? [Theme.accent.opacity(0.5), Theme.accent]
                                    : [Theme.negative.opacity(0.5), Theme.negative],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, progressWidth))
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }

    private var formattedChange: String {
        let absSeconds = abs(changeSeconds)
        let hours = absSeconds / 3600
        let minutes = (absSeconds % 3600) / 60
        let seconds = absSeconds % 60

        let sign = changeSeconds >= 0 ? "+" : "-"

        if hours > 0 {
            return "\(sign)\(hours)h \(minutes)m \(seconds)s"
        } else {
            return "\(sign)\(minutes)m \(seconds)s"
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()

        VStack(spacing: 20) {
            CompactHeroView(
                changeSeconds: 563,  // 9m 23s
                progress: 0.1,
                isGainingDaylight: true,
                daysSinceSolstice: 17
            )

            CompactHeroView(
                changeSeconds: 5523,  // 1h 32m 3s
                progress: 0.45,
                isGainingDaylight: true,
                daysSinceSolstice: 82
            )

            CompactHeroView(
                changeSeconds: -2340,
                progress: 0.3,
                isGainingDaylight: false,
                daysSinceSolstice: 55
            )
        }
        .padding()
    }
}
