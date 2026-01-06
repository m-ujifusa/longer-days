import Foundation
import CoreLocation

struct DaylightData: Codable {
    let date: Date
    let daylightMinutes: Int
    let sunrise: Date
    let sunset: Date

    var formattedDuration: String {
        let hours = daylightMinutes / 60
        let minutes = daylightMinutes % 60
        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        }
        return "\(minutes) min"
    }
}

// MARK: - Comparison Results

struct DaylightComparison {
    let dailyChange: Int  // Minutes gained/lost compared to yesterday
    let cumulativeChange: Int  // Minutes gained/lost since solstice
    let isGainingDaylight: Bool
    let referenceSolstice: Date
    let solsticeType: SolsticeInfo.SolsticeType

    var dailyChangeFormatted: String {
        if dailyChange == 0 {
            return "Same as yesterday"
        } else if dailyChange > 0 {
            return "+\(dailyChange) min today"
        } else {
            return "\(abs(dailyChange)) fewer minutes today"
        }
    }

    var cumulativeChangeFormatted: String {
        let absChange = abs(cumulativeChange)
        let hours = absChange / 60
        let minutes = absChange % 60

        let timeString: String
        if hours > 0 {
            timeString = "\(hours) hr \(minutes) min"
        } else {
            timeString = "\(minutes) min"
        }

        let solsticeMonth = solsticeType == .winter ? "Dec 21" : "Jun 21"

        if isGainingDaylight {
            return "+\(timeString) since \(solsticeMonth)"
        } else {
            return "\(timeString) shorter since \(solsticeMonth)"
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
            daylightMinutes: daylightInfo.daylightMinutes,
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

        // Calculate daily change
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let dailyChange: Int
        if let previousData = previousDayData, calendar.isDate(previousData.date, inSameDayAs: yesterday) {
            dailyChange = current.daylightMinutes - previousData.daylightMinutes
        } else if let yesterdayInfo = SolarCalculator.calculateDaylight(for: yesterday, at: location) {
            dailyChange = current.daylightMinutes - yesterdayInfo.daylightMinutes
        } else {
            return nil
        }

        // Get solstice info
        let solsticeInfo = SolsticeInfo(for: today)
        let (referenceSolstice, solsticeType) = solsticeInfo.mostRecentSolstice(before: today)
        let isGaining = solsticeInfo.season(for: today) == .gainingDaylight

        // Calculate cumulative change since solstice
        let cumulativeChange: Int
        if let storedSolsticeData = solsticeData,
           calendar.isDate(storedSolsticeData.date, inSameDayAs: referenceSolstice) {
            cumulativeChange = current.daylightMinutes - storedSolsticeData.daylightMinutes
        } else if let solsticeDaylight = SolarCalculator.calculateDaylight(for: referenceSolstice, at: location) {
            // Store solstice data for future reference
            let solsticeData = DaylightData(
                date: referenceSolstice,
                daylightMinutes: solsticeDaylight.daylightMinutes,
                sunrise: solsticeDaylight.sunrise,
                sunset: solsticeDaylight.sunset
            )
            storeSolsticeData(solsticeData)
            cumulativeChange = current.daylightMinutes - solsticeDaylight.daylightMinutes
        } else {
            return nil
        }

        return DaylightComparison(
            dailyChange: dailyChange,
            cumulativeChange: cumulativeChange,
            isGainingDaylight: isGaining,
            referenceSolstice: referenceSolstice,
            solsticeType: solsticeType
        )
    }
}
