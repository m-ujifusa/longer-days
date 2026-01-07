import SwiftUI

struct TodayStatsView: View {
    let daylightDuration: TimeInterval
    let dailyChangeSeconds: Int
    let sunrise: Date
    let sunset: Date
    let firstLight: Date?
    let lastLight: Date?
    let isGainingDaylight: Bool

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Today's Daylight")
                    .font(.headline)
                    .foregroundColor(Theme.primaryText)
                Spacer()
            }

            // Main stats row
            HStack(alignment: .firstTextBaseline) {
                Text(formattedDuration)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.primaryText)

                Spacer()

                HStack(spacing: 4) {
                    Text(formattedDailyChange)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(isGainingDaylight ? Theme.accent : Theme.negative)

                    Image(systemName: isGainingDaylight ? "arrow.up" : "arrow.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isGainingDaylight ? Theme.accent : Theme.negative)
                }
            }

            // First Light / Last Light row
            if let firstLight = firstLight, let lastLight = lastLight {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("First Light")
                            .font(.caption)
                            .foregroundColor(Theme.secondaryText.opacity(0.7))
                        Text(timeFormatter.string(from: firstLight))
                            .font(.subheadline)
                            .foregroundColor(Theme.secondaryText)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Last Light")
                            .font(.caption)
                            .foregroundColor(Theme.secondaryText.opacity(0.7))
                        Text(timeFormatter.string(from: lastLight))
                            .font(.subheadline)
                            .foregroundColor(Theme.secondaryText)
                    }
                }
            }

            // Sunrise/Sunset row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sunrise.fill")
                        .foregroundColor(Theme.accentSecondary)
                        .font(.system(size: 16))
                    Text(timeFormatter.string(from: sunrise))
                        .font(.subheadline)
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "sunset.fill")
                        .foregroundColor(Theme.accentSecondary)
                        .font(.system(size: 16))
                    Text(timeFormatter.string(from: sunset))
                        .font(.subheadline)
                        .foregroundColor(Theme.secondaryText)
                }
            }
        }
        .padding(20)
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }

    private var formattedDuration: String {
        let hours = Int(daylightDuration) / 3600
        let minutes = (Int(daylightDuration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private var formattedDailyChange: String {
        let absSeconds = abs(dailyChangeSeconds)
        let minutes = absSeconds / 60
        let seconds = absSeconds % 60

        let sign = dailyChangeSeconds >= 0 ? "+" : "-"

        if minutes > 0 {
            return "\(sign)\(minutes)m \(seconds)s"
        } else {
            return "\(sign)\(seconds)s"
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()

        TodayStatsView(
            daylightDuration: 33120,  // 9h 12m
            dailyChangeSeconds: 138,   // 2m 18s
            sunrise: Calendar.current.date(bySettingHour: 7, minute: 42, second: 0, of: Date())!,
            sunset: Calendar.current.date(bySettingHour: 16, minute: 54, second: 0, of: Date())!,
            firstLight: Calendar.current.date(bySettingHour: 7, minute: 12, second: 0, of: Date())!,
            lastLight: Calendar.current.date(bySettingHour: 17, minute: 24, second: 0, of: Date())!,
            isGainingDaylight: true
        )
        .padding()
    }
}
