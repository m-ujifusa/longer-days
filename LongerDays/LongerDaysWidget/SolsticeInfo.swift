import Foundation

struct SolsticeInfo {
    let winterSolstice: Date
    let summerSolstice: Date
    let springEquinox: Date
    let fallEquinox: Date
    let year: Int

    enum SolsticeType {
        case winter
        case summer
    }

    enum EquinoxType {
        case spring
        case fall
    }

    enum Season {
        case gainingDaylight  // Dec 21 - Jun 21
        case losingDaylight   // Jun 21 - Dec 21
    }

    // MARK: - Initialization

    init(for year: Int) {
        self.year = year
        self.winterSolstice = SolsticeInfo.calculateWinterSolstice(for: year)
        self.summerSolstice = SolsticeInfo.calculateSummerSolstice(for: year)
        self.springEquinox = SolsticeInfo.calculateSpringEquinox(for: year)
        self.fallEquinox = SolsticeInfo.calculateFallEquinox(for: year)
    }

    init(for date: Date) {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        self.init(for: year)
    }

    // MARK: - Public Methods

    /// Check if the given date is a solstice day
    func isSolstice(_ date: Date) -> SolsticeType? {
        let calendar = Calendar.current

        if calendar.isDate(date, inSameDayAs: winterSolstice) {
            return .winter
        }
        if calendar.isDate(date, inSameDayAs: summerSolstice) {
            return .summer
        }
        return nil
    }

    /// Get the current season (gaining or losing daylight)
    func season(for date: Date) -> Season {
        let calendar = Calendar.current

        // Get current year's solstices
        let currentYear = calendar.component(.year, from: date)
        let currentYearInfo = SolsticeInfo(for: currentYear)

        // Check if we're between winter and summer solstice (gaining daylight)
        // Need to handle year boundary (Dec 21 - Jun 21 spans two years)

        let previousWinterSolstice = SolsticeInfo.calculateWinterSolstice(for: currentYear - 1)

        if date >= previousWinterSolstice && date < currentYearInfo.summerSolstice {
            return .gainingDaylight
        } else if date >= currentYearInfo.winterSolstice {
            return .gainingDaylight
        }

        return .losingDaylight
    }

    /// Get the most recent solstice date relative to a given date
    func mostRecentSolstice(before date: Date) -> (date: Date, type: SolsticeType) {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: date)

        let currentYearInfo = SolsticeInfo(for: currentYear)
        let previousYearInfo = SolsticeInfo(for: currentYear - 1)

        // Build list of recent solstices
        let solstices: [(Date, SolsticeType)] = [
            (previousYearInfo.winterSolstice, .winter),
            (currentYearInfo.summerSolstice, .summer),
            (currentYearInfo.winterSolstice, .winter)
        ]

        // Find the most recent one before the given date
        var mostRecent: (Date, SolsticeType) = (previousYearInfo.winterSolstice, .winter)

        for (solsticeDate, type) in solstices {
            if solsticeDate <= date {
                mostRecent = (solsticeDate, type)
            }
        }

        return mostRecent
    }

    /// Check if notifications should be paused based on summer mode setting
    func shouldPauseForSummer(date: Date, summerModeEnabled: Bool) -> Bool {
        guard summerModeEnabled else { return false }

        let season = self.season(for: date)
        return season == .losingDaylight
    }

    // MARK: - Solstice Calculation

    /// Calculate winter solstice date for a given year (approximately December 21-22)
    private static func calculateWinterSolstice(for year: Int) -> Date {
        // Winter solstice occurs around December 21-22
        // Using astronomical approximation: JDE = 2451900.05952 + 365.242189623 * k
        // where k is the year offset from 2000

        let k = Double(year - 2000)
        let jde = 2451900.05952 + 365.242189623 * k

        // Convert JDE to Date
        return julianDayToDate(jde)
    }

    /// Calculate summer solstice date for a given year (approximately June 20-21)
    private static func calculateSummerSolstice(for year: Int) -> Date {
        // Summer solstice occurs around June 20-21
        // Using astronomical approximation

        let k = Double(year - 2000)
        let jde = 2451716.56767 + 365.241626 * k

        return julianDayToDate(jde)
    }

    /// Calculate spring equinox date for a given year (approximately March 20)
    private static func calculateSpringEquinox(for year: Int) -> Date {
        let k = Double(year - 2000)
        let jde = 2451623.80984 + 365.242374 * k
        return julianDayToDate(jde)
    }

    /// Calculate fall equinox date for a given year (approximately September 22)
    private static func calculateFallEquinox(for year: Int) -> Date {
        let k = Double(year - 2000)
        let jde = 2451810.21715 + 365.242018 * k
        return julianDayToDate(jde)
    }

    /// Convert Julian Day to Date
    private static func julianDayToDate(_ julianDay: Double) -> Date {
        // Julian Day epoch is -4713 BCE, but we use a simpler conversion
        // JD 2440587.5 = Unix epoch (1970-01-01 00:00:00 UTC)

        let unixTime = (julianDay - 2440587.5) * 86400.0
        return Date(timeIntervalSince1970: unixTime)
    }

    // MARK: - Countdown Helpers

    /// Days since the most recent solstice
    func daysSinceSolstice(from date: Date) -> Int {
        let (solsticeDate, _) = mostRecentSolstice(before: date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: solsticeDate, to: date)
        return components.day ?? 0
    }

    /// Days until the next equinox
    func daysUntilEquinox(from date: Date) -> (days: Int, type: EquinoxType)? {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: date)

        let currentYearInfo = SolsticeInfo(for: currentYear)
        let nextYearInfo = SolsticeInfo(for: currentYear + 1)

        let equinoxes: [(Date, EquinoxType)] = [
            (currentYearInfo.springEquinox, .spring),
            (currentYearInfo.fallEquinox, .fall),
            (nextYearInfo.springEquinox, .spring)
        ]

        for (equinoxDate, type) in equinoxes {
            if equinoxDate > date {
                let components = calendar.dateComponents([.day], from: date, to: equinoxDate)
                if let days = components.day {
                    return (days, type)
                }
            }
        }
        return nil
    }

    /// Days until the next solstice
    func daysUntilSolstice(from date: Date) -> (days: Int, type: SolsticeType)? {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: date)

        let currentYearInfo = SolsticeInfo(for: currentYear)
        let nextYearInfo = SolsticeInfo(for: currentYear + 1)

        let solstices: [(Date, SolsticeType)] = [
            (currentYearInfo.summerSolstice, .summer),
            (currentYearInfo.winterSolstice, .winter),
            (nextYearInfo.summerSolstice, .summer)
        ]

        for (solsticeDate, type) in solstices {
            if solsticeDate > date {
                let components = calendar.dateComponents([.day], from: date, to: solsticeDate)
                if let days = components.day {
                    return (days, type)
                }
            }
        }
        return nil
    }

    /// Get progress through current half-year (0.0 to 1.0)
    /// From winter solstice to summer solstice, or summer to winter
    func progressThroughHalfYear(for date: Date) -> Double {
        let calendar = Calendar.current
        let (startSolstice, startType) = mostRecentSolstice(before: date)

        let endSolstice: Date
        if startType == .winter {
            // Next is summer solstice
            let currentYear = calendar.component(.year, from: date)
            let info = SolsticeInfo(for: currentYear)
            endSolstice = info.summerSolstice > date ? info.summerSolstice : SolsticeInfo(for: currentYear + 1).summerSolstice
        } else {
            // Next is winter solstice
            let currentYear = calendar.component(.year, from: date)
            let info = SolsticeInfo(for: currentYear)
            endSolstice = info.winterSolstice > date ? info.winterSolstice : SolsticeInfo(for: currentYear + 1).winterSolstice
        }

        let totalDuration = endSolstice.timeIntervalSince(startSolstice)
        let elapsed = date.timeIntervalSince(startSolstice)

        return min(1.0, max(0.0, elapsed / totalDuration))
    }
}

// MARK: - Solstice Messages

extension SolsticeInfo {
    static func solsticeMessage(for type: SolsticeType) -> String {
        switch type {
        case .winter:
            return "Happy Winter Solstice! The shortest day is here—every day gets brighter from now on!"
        case .summer:
            return "Happy Summer Solstice! The longest day of the year. Enjoy the light!"
        }
    }

    static func solsticeEmoji(for type: SolsticeType) -> String {
        switch type {
        case .winter:
            return "🌟"
        case .summer:
            return "☀️"
        }
    }
}
