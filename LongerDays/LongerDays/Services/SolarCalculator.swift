import Foundation
import CoreLocation

/// Solar calculator using NOAA algorithm for accurate sunrise/sunset calculations
struct SolarCalculator {

    struct DaylightInfo {
        let sunrise: Date
        let sunset: Date
        let daylightDuration: TimeInterval

        var daylightMinutes: Int {
            Int(daylightDuration / 60)
        }

        var formattedDuration: String {
            let hours = Int(daylightDuration) / 3600
            let minutes = (Int(daylightDuration) % 3600) / 60
            return "\(hours) hr \(minutes) min"
        }
    }

    // MARK: - Public Methods

    /// Calculate sunrise and sunset for a given date and location
    static func calculateDaylight(for date: Date, at location: CLLocationCoordinate2D) -> DaylightInfo? {
        let timeZone = TimeZone.current

        guard let sunrise = calculateSunrise(for: date, at: location, timeZone: timeZone),
              let sunset = calculateSunset(for: date, at: location, timeZone: timeZone) else {
            return nil
        }

        let duration = sunset.timeIntervalSince(sunrise)
        return DaylightInfo(sunrise: sunrise, sunset: sunset, daylightDuration: duration)
    }

    /// Calculate the change in daylight minutes between two dates
    static func daylightChange(from previousDate: Date, to currentDate: Date, at location: CLLocationCoordinate2D) -> Int? {
        guard let previous = calculateDaylight(for: previousDate, at: location),
              let current = calculateDaylight(for: currentDate, at: location) else {
            return nil
        }
        return current.daylightMinutes - previous.daylightMinutes
    }

    /// Calculate cumulative daylight change since a reference date
    static func cumulativeDaylightChange(since referenceDate: Date, to currentDate: Date, at location: CLLocationCoordinate2D) -> Int? {
        guard let reference = calculateDaylight(for: referenceDate, at: location),
              let current = calculateDaylight(for: currentDate, at: location) else {
            return nil
        }
        return current.daylightMinutes - reference.daylightMinutes
    }

    // MARK: - NOAA Solar Calculation Algorithm

    private static func calculateSunrise(for date: Date, at location: CLLocationCoordinate2D, timeZone: TimeZone) -> Date? {
        return calculateSunTime(for: date, at: location, timeZone: timeZone, isRising: true)
    }

    private static func calculateSunset(for date: Date, at location: CLLocationCoordinate2D, timeZone: TimeZone) -> Date? {
        return calculateSunTime(for: date, at: location, timeZone: timeZone, isRising: false)
    }

    private static func calculateSunTime(for date: Date, at location: CLLocationCoordinate2D, timeZone: TimeZone, isRising: Bool) -> Date? {
        let calendar = Calendar.current
        let latitude = location.latitude
        let longitude = location.longitude

        // Get the day of year
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1

        // Calculate timezone offset in hours
        let tzOffset = Double(timeZone.secondsFromGMT(for: date)) / 3600.0

        // Calculate the fractional year (gamma) in radians
        let gamma = 2.0 * .pi / 365.0 * (Double(dayOfYear) - 1.0 + (12.0 - 12.0) / 24.0)

        // Equation of time (minutes)
        let eqTime = 229.18 * (0.000075 + 0.001868 * cos(gamma) - 0.032077 * sin(gamma)
                               - 0.014615 * cos(2 * gamma) - 0.040849 * sin(2 * gamma))

        // Solar declination (radians)
        let decl = 0.006918 - 0.399912 * cos(gamma) + 0.070257 * sin(gamma)
                 - 0.006758 * cos(2 * gamma) + 0.000907 * sin(2 * gamma)
                 - 0.002697 * cos(3 * gamma) + 0.00148 * sin(3 * gamma)

        // Hour angle for sunrise/sunset
        let latRad = latitude * .pi / 180.0
        let zenith = 90.833 * .pi / 180.0 // Official sunrise/sunset zenith

        let cosHA = (cos(zenith) / (cos(latRad) * cos(decl))) - tan(latRad) * tan(decl)

        // Check if sun never rises or sets at this location on this day
        if cosHA > 1.0 || cosHA < -1.0 {
            return nil
        }

        var ha = acos(cosHA) * 180.0 / .pi

        if isRising {
            ha = -ha
        }

        // Calculate solar noon
        let solarNoon = (720.0 - 4.0 * longitude - eqTime + tzOffset * 60.0) / 1440.0

        // Calculate sunrise/sunset time as fraction of day
        let timeFrac = solarNoon + ha * 4.0 / 1440.0

        // Convert to Date
        let startOfDay = calendar.startOfDay(for: date)
        let secondsFromMidnight = timeFrac * 24.0 * 3600.0

        return startOfDay.addingTimeInterval(secondsFromMidnight)
    }
}
