import Foundation
import CoreLocation

/// Data structure for widget display - lightweight and Codable
struct WidgetData: Codable {
    let lastUpdated: Date
    let latitude: Double
    let longitude: Double
    let locationName: String

    // Calculated values
    let cumulativeChangeSeconds: Int
    let dailyChangeSeconds: Int
    let isGainingDaylight: Bool
    let solsticeLabel: String  // "Dec 21" or "Jun 21"
    let progress: Double       // 0.0 to 1.0 through half-year

    // Formatted strings for display
    var cumulativeFormatted: String {
        formatTimeChange(abs(cumulativeChangeSeconds))
    }

    var dailyFormatted: String {
        let sign = dailyChangeSeconds >= 0 ? "+" : "-"
        return "\(sign)\(formatTimeChange(abs(dailyChangeSeconds)))"
    }

    private func formatTimeChange(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
}

/// Manager for reading/writing widget data via App Groups
class SharedDataManager {
    static let shared = SharedDataManager()

    static let appGroupIdentifier = "group.com.ujifusa.longerdays.shared"
    private let widgetDataKey = "widgetData"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: SharedDataManager.appGroupIdentifier)
    }

    private init() {}

    // MARK: - Write (called by main app)

    func saveWidgetData(_ data: WidgetData) {
        guard let defaults = sharedDefaults,
              let encoded = try? JSONEncoder().encode(data) else { return }
        defaults.set(encoded, forKey: widgetDataKey)
    }

    // MARK: - Read (called by widget)

    func loadWidgetData() -> WidgetData? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: widgetDataKey),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return nil
        }
        return decoded
    }

    // MARK: - Save Location to Shared Container

    func saveLocation(latitude: Double, longitude: Double, name: String) {
        guard let defaults = sharedDefaults else { return }
        defaults.set(latitude, forKey: "savedLatitude")
        defaults.set(longitude, forKey: "savedLongitude")
        defaults.set(name, forKey: "savedLocationName")
    }

    func loadLocation() -> (coordinate: CLLocationCoordinate2D, name: String)? {
        guard let defaults = sharedDefaults,
              defaults.object(forKey: "savedLatitude") != nil else {
            return nil
        }

        let latitude = defaults.double(forKey: "savedLatitude")
        let longitude = defaults.double(forKey: "savedLongitude")
        let name = defaults.string(forKey: "savedLocationName") ?? ""

        return (CLLocationCoordinate2D(latitude: latitude, longitude: longitude), name)
    }

    // MARK: - Calculate and Save (called by main app)

    func updateWidgetData(location: CLLocationCoordinate2D, locationName: String) {
        let today = Date()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Get solstice info
        let solsticeInfo = SolsticeInfo(for: today)
        let (recentSolstice, solsticeType) = solsticeInfo.mostRecentSolstice(before: today)
        let isGaining = solsticeInfo.season(for: today) == .gainingDaylight

        // Calculate changes using existing SolarCalculator
        let cumulativeSeconds = SolarCalculator.cumulativeDaylightChangeSeconds(
            since: recentSolstice,
            to: today,
            at: location
        ) ?? 0

        let dailySeconds = SolarCalculator.dailyChangeSeconds(
            from: yesterday,
            to: today,
            at: location
        ) ?? 0

        let progress = solsticeInfo.progressThroughHalfYear(for: today)

        // Format solstice label based on type
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let solsticeLabel = dateFormatter.string(from: recentSolstice)

        let widgetData = WidgetData(
            lastUpdated: today,
            latitude: location.latitude,
            longitude: location.longitude,
            locationName: locationName,
            cumulativeChangeSeconds: cumulativeSeconds,
            dailyChangeSeconds: dailySeconds,
            isGainingDaylight: isGaining,
            solsticeLabel: solsticeLabel,
            progress: progress
        )

        saveWidgetData(widgetData)
        saveLocation(latitude: location.latitude, longitude: location.longitude, name: locationName)
    }
}
