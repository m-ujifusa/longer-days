import SwiftUI

struct SunriseSunsetCard: View {
    let sunrise: Date
    let sunset: Date
    let firstLight: Date?
    let lastLight: Date?
    let daylightDuration: TimeInterval
    let currentTime: Date

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }()

    private let periodFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Header with current time and remaining daylight
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedCurrentTime)
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.primaryText)

                Text(remainingDaylightText)
                    .font(.subheadline)
                    .foregroundColor(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Sun Arc
            SunArcView(
                sunrise: sunrise,
                sunset: sunset,
                firstLight: firstLight,
                lastLight: lastLight,
                currentTime: currentTime
            )
            .padding(.horizontal, 16)

            // Divider
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.top, 16)

            // Detail rows
            VStack(spacing: 0) {
                if let firstLight = firstLight {
                    detailRow(label: "First Light", time: firstLight)
                    Divider().background(Color.white.opacity(0.1))
                }

                detailRow(label: "Sunrise", time: sunrise)
                Divider().background(Color.white.opacity(0.1))

                detailRow(label: "Sunset", time: sunset)
                Divider().background(Color.white.opacity(0.1))

                if let lastLight = lastLight {
                    detailRow(label: "Last Light", time: lastLight)
                    Divider().background(Color.white.opacity(0.1))
                }

                totalDaylightRow
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Subviews

    private func detailRow(label: String, time: Date) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(Theme.primaryText)

            Spacer()

            HStack(spacing: 2) {
                Text(timeFormatter.string(from: time))
                    .font(.body)
                    .foregroundColor(Theme.secondaryText)
                Text(periodFormatter.string(from: time).uppercased())
                    .font(.caption)
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .padding(.vertical, 14)
    }

    private var totalDaylightRow: some View {
        HStack {
            Text("Total Daylight")
                .font(.body)
                .foregroundColor(Theme.primaryText)

            Spacer()

            Text(formattedDaylightDuration)
                .font(.body)
                .foregroundColor(Theme.secondaryText)
        }
        .padding(.vertical, 14)
    }

    // MARK: - Computed Properties

    private var formattedCurrentTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: currentTime).uppercased()
    }

    private var remainingDaylightText: String {
        if currentTime < sunrise {
            let remaining = sunrise.timeIntervalSince(currentTime)
            return "Sunrise in \(formatDuration(remaining))"
        } else if currentTime > sunset {
            return "Sun has set"
        } else {
            let remaining = sunset.timeIntervalSince(currentTime)
            return "Daylight remaining: \(formatDuration(remaining))"
        }
    }

    private var formattedDaylightDuration: String {
        formatDuration(daylightDuration)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)HR \(minutes)MIN"
        } else {
            return "\(minutes)MIN"
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()

        ScrollView {
            SunriseSunsetCard(
                sunrise: Calendar.current.date(bySettingHour: 7, minute: 51, second: 0, of: Date())!,
                sunset: Calendar.current.date(bySettingHour: 16, minute: 49, second: 0, of: Date())!,
                firstLight: Calendar.current.date(bySettingHour: 7, minute: 17, second: 0, of: Date())!,
                lastLight: Calendar.current.date(bySettingHour: 17, minute: 22, second: 0, of: Date())!,
                daylightDuration: 8 * 3600 + 58 * 60,
                currentTime: Date()
            )
            .padding()
        }
    }
}
