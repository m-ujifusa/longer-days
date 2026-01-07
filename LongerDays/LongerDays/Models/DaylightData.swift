import Foundation
import CoreLocation

struct DaylightData: Codable {
    let date: Date
    let daylightSeconds: Int
    let sunrise: Date
    let sunset: Date

    var daylightMinutes: Int {
        daylightSeconds / 60
    }

    var formattedDuration: String {
        let hours = daylightSeconds / 3600
        let minutes = (daylightSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        }
        return "\(minutes) min"
    }
}

// MARK: - Comparison Results

struct DaylightComparison {
    let dailyChangeSeconds: Int  // Seconds gained/lost compared to yesterday
    let cumulativeChangeSeconds: Int  // Seconds gained/lost since solstice
    let isGainingDaylight: Bool
    let referenceSolstice: Date
    let solsticeType: SolsticeInfo.SolsticeType

    var dailyChangeFormatted: String {
        if dailyChangeSeconds == 0 {
            return "Same as yesterday"
        }

        let absSeconds = abs(dailyChangeSeconds)
        let minutes = absSeconds / 60
        let seconds = absSeconds % 60

        let timeString: String
        if minutes > 0 {
            timeString = "\(minutes)m \(seconds)s"
        } else {
            timeString = "\(seconds)s"
        }

        if dailyChangeSeconds > 0 {
            return "+\(timeString) today"
        } else {
            return "-\(timeString) today"
        }
    }

    var cumulativeChangeFormatted: String {
        let absSeconds = abs(cumulativeChangeSeconds)
        let hours = absSeconds / 3600
        let minutes = (absSeconds % 3600) / 60
        let seconds = absSeconds % 60

        let timeString: String
        if hours > 0 {
            timeString = "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes > 0 {
            timeString = "\(minutes)m \(seconds)s"
        } else {
            timeString = "\(seconds)s"
        }

        let solsticeMonth = solsticeType == .winter ? "Dec 21" : "Jun 21"

        if isGainingDaylight {
            return "+\(timeString) since \(solsticeMonth)"
        } else {
            return "-\(timeString) since \(solsticeMonth)"
        }
    }

    var emoji: String {
        isGainingDaylight ? "☀️" : "🌅"
    }
}

// MARK: - Data Manager

class DaylightDataManager: ObservableObject {
    private let userDefaults = UserDefaults.standard
    private let previousDataKey = "previousDaylightData"
    private let solsticeDataKey = "solsticeDaylightData"

    @Published var previousDayData: DaylightData?
    @Published var solsticeData: DaylightData?

    init() {
        loadStoredData()
    }

    func loadStoredData() {
        if let data = userDefaults.data(forKey: previousDataKey),
           let decoded = try? JSONDecoder().decode(DaylightData.self, from: data) {
            previousDayData = decoded
        }

        if let data = userDefaults.data(forKey: solsticeDataKey),
           let decoded = try? JSONDecoder().decode(DaylightData.self, from: data) {
            solsticeData = decoded
        }
    }

    func storeDaylightData(_ data: DaylightData) {
        previousDayData = data
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: previousDataKey)
        }
    }

    func storeSolsticeData(_ data: DaylightData) {
        solsticeData = data
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: solsticeDataKey)
        }
    }

    /// Calculate current daylight data and comparison
    func calculateDaylightInfo(for date: Date, at location: CLLocationCoordinate2D) -> (current: DaylightData, comparison: DaylightComparison?)? {
        guard let daylightInfo = SolarCalculator.calculateDaylight(for: date, at: location) else {
            return nil
        }

        let currentData = DaylightData(
            date: date,
            daylightSeconds: Int(daylightInfo.daylightDuration),
            sunrise: daylightInfo.sunrise,
            sunset: daylightInfo.sunset
        )

        // Calculate comparison if we have previous data
        let comparison = calculateComparison(for: currentData, at: location)

        return (currentData, comparison)
    }

    private func calculateComparison(for current: DaylightData, at location: CLLocationCoordinate2D) -> DaylightComparison? {
        let calendar = Calendar.current
        let today = current.date

        // Calculate daily change in seconds
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let dailyChangeSeconds: Int
        if let previousData = previousDayData, calendar.isDate(previousData.date, inSameDayAs: yesterday) {
            dailyChangeSeconds = current.daylightSeconds - previousData.daylightSeconds
        } else if let yesterdayInfo = SolarCalculator.calculateDaylight(for: yesterday, at: location) {
            dailyChangeSeconds = current.daylightSeconds - Int(yesterdayInfo.daylightDuration)
        } else {
            return nil
        }

        // Get solstice info
        let solsticeInfo = SolsticeInfo(for: today)
        let (referenceSolstice, solsticeType) = solsticeInfo.mostRecentSolstice(before: today)
        let isGaining = solsticeInfo.season(for: today) == .gainingDaylight

        // Calculate cumulative change since solstice in seconds
        let cumulativeChangeSeconds: Int
        if let storedSolsticeData = solsticeData,
           calendar.isDate(storedSolsticeData.date, inSameDayAs: referenceSolstice) {
            cumulativeChangeSeconds = current.daylightSeconds - storedSolsticeData.daylightSeconds
        } else if let solsticeDaylight = SolarCalculator.calculateDaylight(for: referenceSolstice, at: location) {
            // Store solstice data for future reference
            let solsticeData = DaylightData(
                date: referenceSolstice,
                daylightSeconds: Int(solsticeDaylight.daylightDuration),
                sunrise: solsticeDaylight.sunrise,
                sunset: solsticeDaylight.sunset
            )
            storeSolsticeData(solsticeData)
            cumulativeChangeSeconds = current.daylightSeconds - Int(solsticeDaylight.daylightDuration)
        } else {
            return nil
        }

        return DaylightComparison(
            dailyChangeSeconds: dailyChangeSeconds,
            cumulativeChangeSeconds: cumulativeChangeSeconds,
            isGainingDaylight: isGaining,
            referenceSolstice: referenceSolstice,
            solsticeType: solsticeType
        )
    }
}
