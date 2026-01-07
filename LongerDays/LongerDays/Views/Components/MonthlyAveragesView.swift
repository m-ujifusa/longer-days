import SwiftUI
import CoreLocation

struct MonthlyAveragesView: View {
    let location: CLLocationCoordinate2D
    @State private var monthlyData: [MonthData] = []
    @State private var longestDaylight: (duration: TimeInterval, date: String)?

    struct MonthData: Identifiable {
        let id = UUID()
        let month: String
        let sunrise: Date
        let sunset: Date
        let daylightDuration: TimeInterval
    }

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Sunrise and Sunset Averages")
                    .font(.headline)
                    .foregroundColor(Theme.primaryText)

                if let longest = longestDaylight {
                    Text("Longest daylight: \(formatDuration(longest.duration)) \(longest.date)")
                        .font(.subheadline)
                        .foregroundColor(Theme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)

            // Monthly rows
            VStack(spacing: 0) {
                ForEach(monthlyData) { data in
                    monthRow(data: data)
                    if data.month != "Dec" {
                        Divider().background(Color.white.opacity(0.1))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(Theme.cardBackground)
        .cornerRadius(16)
        .onAppear {
            calculateMonthlyData()
        }
    }

    // MARK: - Subviews

    private func monthRow(data: MonthData) -> some View {
        HStack(spacing: 12) {
            Text(data.month)
                .font(.body.weight(.medium))
                .foregroundColor(Theme.primaryText)
                .frame(width: 40, alignment: .leading)

            Text(timeFormatter.string(from: data.sunrise).uppercased())
                .font(.caption)
                .foregroundColor(Theme.secondaryText)
                .frame(width: 65, alignment: .trailing)

            // Daylight bar
            GeometryReader { geometry in
                let maxWidth = geometry.size.width
                let barWidth = calculateBarWidth(duration: data.daylightDuration, maxWidth: maxWidth)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.accent)
                    .frame(width: barWidth, height: 4)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(height: 4)

            Text(timeFormatter.string(from: data.sunset).uppercased())
                .font(.caption)
                .foregroundColor(Theme.secondaryText)
                .frame(width: 65, alignment: .leading)
        }
        .padding(.vertical, 14)
    }

    // MARK: - Calculations

    private func calculateMonthlyData() {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

        var data: [MonthData] = []
        var maxDaylight: TimeInterval = 0
        var maxDaylightDate = ""

        for (index, monthName) in months.enumerated() {
            // Get the 15th of each month (middle of month for average)
            var components = DateComponents()
            components.year = currentYear
            components.month = index + 1
            components.day = 15

            guard let date = calendar.date(from: components),
                  let daylightInfo = SolarCalculator.calculateDaylight(for: date, at: location) else {
                continue
            }

            data.append(MonthData(
                month: monthName,
                sunrise: daylightInfo.sunrise,
                sunset: daylightInfo.sunset,
                daylightDuration: daylightInfo.daylightDuration
            ))

            // Track longest daylight
            if daylightInfo.daylightDuration > maxDaylight {
                maxDaylight = daylightInfo.daylightDuration
                // Summer solstice is around June 21
                maxDaylightDate = "Jun 21"
            }
        }

        monthlyData = data
        longestDaylight = (maxDaylight, maxDaylightDate)
    }

    private func calculateBarWidth(duration: TimeInterval, maxWidth: CGFloat) -> CGFloat {
        // Scale bars relative to the range of daylight hours
        // Shortest day ~8h, longest ~16h depending on latitude
        guard let minDuration = monthlyData.map({ $0.daylightDuration }).min(),
              let maxDuration = monthlyData.map({ $0.daylightDuration }).max() else {
            return maxWidth * 0.5
        }

        let range = maxDuration - minDuration
        if range == 0 { return maxWidth * 0.5 }

        // Normalize to 30%-100% of available width
        let normalized = (duration - minDuration) / range
        let minBarWidth: CGFloat = 0.3
        let barFraction = minBarWidth + (1 - minBarWidth) * normalized

        return maxWidth * barFraction
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)HR \(minutes)MIN"
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()

        ScrollView {
            MonthlyAveragesView(
                location: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)  // Seattle
            )
            .padding()
        }
    }
}
