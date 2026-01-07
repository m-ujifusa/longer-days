import SwiftUI

struct VelocityView: View {
    let velocitySeconds: Int  // seconds per day (current)
    let peakVelocitySeconds: Int  // seconds per day at equinox
    let peakDate: Date  // when peak occurs
    let isGainingDaylight: Bool

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 16) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(velocityText)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.primaryText)

                    Text(percentageText)
                        .font(.subheadline)
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                // Trend indicator
                Image(systemName: isGainingDaylight ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isGainingDaylight ? Theme.accent : Theme.negative)
            }

            // Progress bar
            GeometryReader { geometry in
                let width = geometry.size.width
                let progressWidth = width * progressPercentage

                ZStack(alignment: .leading) {
                    // Background track
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

            // Peak forecast
            HStack {
                Text("Peak:")
                    .font(.subheadline)
                    .foregroundColor(Theme.secondaryText)

                Text(peakVelocityText)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Theme.primaryText)

                Text("on \(dateFormatter.string(from: peakDate))")
                    .font(.subheadline)
                    .foregroundColor(Theme.secondaryText)

                Spacer()
            }
        }
        .padding(20)
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }

    private var velocityText: String {
        let absSeconds = abs(velocitySeconds)
        let minutes = absSeconds / 60
        let seconds = absSeconds % 60

        let action = isGainingDaylight ? "Gaining" : "Losing"

        if minutes > 0 {
            return "\(action) \(minutes)m \(seconds)s/day"
        } else {
            return "\(action) \(seconds)s/day"
        }
    }

    private var peakVelocityText: String {
        let absSeconds = abs(peakVelocitySeconds)
        let minutes = absSeconds / 60
        let seconds = absSeconds % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s/day"
        } else {
            return "\(seconds)s/day"
        }
    }

    private var progressPercentage: Double {
        guard peakVelocitySeconds > 0 else { return 0 }
        let percentage = Double(abs(velocitySeconds)) / Double(abs(peakVelocitySeconds))
        return min(1.0, max(0, percentage))
    }

    private var percentageText: String {
        let percent = Int(progressPercentage * 100)
        return "\(percent)% of peak rate"
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()

        VStack(spacing: 20) {
            VelocityView(
                velocitySeconds: 72,  // 1m 12s
                peakVelocitySeconds: 208,  // 3m 28s
                peakDate: Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 20))!,
                isGainingDaylight: true
            )

            VelocityView(
                velocitySeconds: 195,  // 3m 15s (near peak)
                peakVelocitySeconds: 208,
                peakDate: Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 20))!,
                isGainingDaylight: true
            )

            VelocityView(
                velocitySeconds: -150,
                peakVelocitySeconds: 208,
                peakDate: Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 22))!,
                isGainingDaylight: false
            )
        }
        .padding()
    }
}
