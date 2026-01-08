import XCTest
import CoreLocation
@testable import LongerDays

final class SolarCalculatorTests: XCTestCase {

    // Minneapolis coordinates from the spec
    let minneapolis = CLLocationCoordinate2D(latitude: 44.9778, longitude: -93.2650)

    // MARK: - Daylight Duration Tests

    func testWinterSolsticeDaylight() {
        // December 21, 2024 - shortest day ~8 hours 46 minutes (526 minutes)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 21
        let winterSolstice = calendar.date(from: components)!

        guard let daylight = SolarCalculator.calculateDaylight(for: winterSolstice, at: minneapolis) else {
            XCTFail("Failed to calculate winter solstice daylight")
            return
        }

        // Expected: ~526 minutes (8 hr 46 min), allow 10 minute tolerance
        let expectedMinutes = 526
        assertIntEqual(daylight.daylightMinutes, expectedMinutes, accuracy: 10,
                      "Winter solstice daylight should be approximately 8 hr 46 min")

        print("Winter Solstice (Dec 21, 2024):")
        print("  Sunrise: \(daylight.sunrise)")
        print("  Sunset: \(daylight.sunset)")
        print("  Duration: \(daylight.daylightMinutes) minutes (\(daylight.formattedDuration))")
    }

    func testSummerSolsticeDaylight() {
        // June 20, 2025 - longest day ~15 hours 37 minutes (937 minutes)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2025
        components.month = 6
        components.day = 20
        let summerSolstice = calendar.date(from: components)!

        guard let daylight = SolarCalculator.calculateDaylight(for: summerSolstice, at: minneapolis) else {
            XCTFail("Failed to calculate summer solstice daylight")
            return
        }

        // Expected: ~937 minutes (15 hr 37 min), allow 10 minute tolerance
        let expectedMinutes = 937
        assertIntEqual(daylight.daylightMinutes, expectedMinutes, accuracy: 10,
                      "Summer solstice daylight should be approximately 15 hr 37 min")

        print("Summer Solstice (Jun 20, 2025):")
        print("  Sunrise: \(daylight.sunrise)")
        print("  Sunset: \(daylight.sunset)")
        print("  Duration: \(daylight.daylightMinutes) minutes (\(daylight.formattedDuration))")
    }

    func testDaylightChange() {
        // Test that daylight increases from Dec 21 to Dec 22
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 21
        let dec21 = calendar.date(from: components)!

        components.day = 22
        let dec22 = calendar.date(from: components)!

        guard let change = SolarCalculator.daylightChange(from: dec21, to: dec22, at: minneapolis) else {
            XCTFail("Failed to calculate daylight change")
            return
        }

        // After winter solstice, days should get longer (change >= 0)
        XCTAssertGreaterThanOrEqual(change, 0,
                                    "Days should start getting longer after winter solstice")

        print("Daylight change from Dec 21 to Dec 22: \(change) minutes")
    }

    // MARK: - Solstice Detection Tests

    func testSolsticeDetection() {
        let calendar = Calendar.current

        // Test winter solstice detection
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 21
        let winterDate = calendar.date(from: components)!

        let solsticeInfo = SolsticeInfo(for: winterDate)
        let winterResult = solsticeInfo.isSolstice(winterDate)
        XCTAssertEqual(winterResult, .winter, "Dec 21, 2024 should be detected as winter solstice")

        // Test summer solstice detection
        components.year = 2025
        components.month = 6
        components.day = 20
        let summerDate = calendar.date(from: components)!

        let summerInfo = SolsticeInfo(for: summerDate)
        let summerResult = summerInfo.isSolstice(summerDate)
        XCTAssertEqual(summerResult, .summer, "Jun 20, 2025 should be detected as summer solstice")

        // Test non-solstice day
        components.month = 3
        components.day = 15
        let regularDate = calendar.date(from: components)!
        let regularResult = summerInfo.isSolstice(regularDate)
        XCTAssertNil(regularResult, "Mar 15 should not be detected as a solstice")
    }

    func testSeasonDetection() {
        let calendar = Calendar.current
        var components = DateComponents()

        // January should be gaining daylight (after winter solstice)
        components.year = 2025
        components.month = 1
        components.day = 15
        let january = calendar.date(from: components)!
        let janInfo = SolsticeInfo(for: january)
        XCTAssertEqual(janInfo.season(for: january), .gainingDaylight,
                      "January should be in 'gaining daylight' season")

        // July should be losing daylight (after summer solstice)
        components.month = 7
        components.day = 15
        let july = calendar.date(from: components)!
        let julyInfo = SolsticeInfo(for: july)
        XCTAssertEqual(julyInfo.season(for: july), .losingDaylight,
                      "July should be in 'losing daylight' season")
    }

    // MARK: - Cumulative Change Tests

    func testCumulativeChange() {
        let calendar = Calendar.current
        var components = DateComponents()

        // Winter solstice
        components.year = 2024
        components.month = 12
        components.day = 21
        let winterSolstice = calendar.date(from: components)!

        // A month later
        components.year = 2025
        components.month = 1
        components.day = 21
        let monthLater = calendar.date(from: components)!

        guard let cumulativeChange = SolarCalculator.cumulativeDaylightChange(
            since: winterSolstice,
            to: monthLater,
            at: minneapolis
        ) else {
            XCTFail("Failed to calculate cumulative change")
            return
        }

        // After a month, we should have gained significant daylight
        XCTAssertGreaterThan(cumulativeChange, 20,
                            "Should have gained at least 20 minutes after a month")

        print("Cumulative daylight change from Dec 21 to Jan 21: \(cumulativeChange) minutes")
    }

    // MARK: - Civil Twilight Tests

    func testCivilTwilightCalculation() {
        // Test that civil dawn is before sunrise and civil dusk is after sunset
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        let testDate = calendar.date(from: components)!

        guard let daylight = SolarCalculator.calculateDaylight(for: testDate, at: minneapolis) else {
            XCTFail("Failed to calculate daylight")
            return
        }

        // Civil dawn (first light) should be before sunrise
        if let civilDawn = daylight.civilDawn {
            XCTAssertLessThan(civilDawn, daylight.sunrise,
                             "Civil dawn should be before sunrise")

            // Civil twilight is typically 20-30 minutes before sunrise
            let difference = daylight.sunrise.timeIntervalSince(civilDawn)
            XCTAssertGreaterThan(difference, 15 * 60, "Civil dawn should be at least 15 min before sunrise")
            XCTAssertLessThan(difference, 45 * 60, "Civil dawn should be less than 45 min before sunrise")

            print("Civil Dawn: \(civilDawn)")
            print("Sunrise: \(daylight.sunrise)")
            print("Difference: \(Int(difference / 60)) minutes")
        } else {
            XCTFail("Civil dawn should be calculated")
        }

        // Civil dusk (last light) should be after sunset
        if let civilDusk = daylight.civilDusk {
            XCTAssertGreaterThan(civilDusk, daylight.sunset,
                                "Civil dusk should be after sunset")

            // Civil twilight is typically 20-30 minutes after sunset
            let difference = civilDusk.timeIntervalSince(daylight.sunset)
            XCTAssertGreaterThan(difference, 15 * 60, "Civil dusk should be at least 15 min after sunset")
            XCTAssertLessThan(difference, 45 * 60, "Civil dusk should be less than 45 min after sunset")

            print("Sunset: \(daylight.sunset)")
            print("Civil Dusk: \(civilDusk)")
            print("Difference: \(Int(difference / 60)) minutes")
        } else {
            XCTFail("Civil dusk should be calculated")
        }
    }

    // MARK: - Seconds Precision Tests

    func testDailyChangeSeconds() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        let day1 = calendar.date(from: components)!

        components.day = 16
        let day2 = calendar.date(from: components)!

        guard let changeSeconds = SolarCalculator.dailyChangeSeconds(from: day1, to: day2, at: minneapolis) else {
            XCTFail("Failed to calculate daily change in seconds")
            return
        }

        // In January, we should be gaining daylight (positive change)
        XCTAssertGreaterThan(changeSeconds, 0, "Should be gaining daylight in January")

        // Typical daily gain in mid-January is 1-3 minutes (60-180 seconds)
        XCTAssertGreaterThan(changeSeconds, 30, "Daily gain should be at least 30 seconds")
        XCTAssertLessThan(changeSeconds, 300, "Daily gain should be less than 5 minutes")

        print("Daily change (Jan 15-16): \(changeSeconds) seconds (\(changeSeconds / 60)m \(changeSeconds % 60)s)")
    }

    func testCumulativeChangeSeconds() {
        let calendar = Calendar.current
        var components = DateComponents()

        // Winter solstice
        components.year = 2024
        components.month = 12
        components.day = 21
        let winterSolstice = calendar.date(from: components)!

        // Two weeks later
        components.year = 2025
        components.month = 1
        components.day = 4
        let twoWeeksLater = calendar.date(from: components)!

        guard let cumulativeSeconds = SolarCalculator.cumulativeDaylightChangeSeconds(
            since: winterSolstice,
            to: twoWeeksLater,
            at: minneapolis
        ) else {
            XCTFail("Failed to calculate cumulative change in seconds")
            return
        }

        // Should have gained some daylight after two weeks
        XCTAssertGreaterThan(cumulativeSeconds, 0, "Should have gained daylight since winter solstice")

        // Expect roughly 5-15 minutes of cumulative gain after 2 weeks
        XCTAssertGreaterThan(cumulativeSeconds, 3 * 60, "Should have gained at least 3 minutes")
        XCTAssertLessThan(cumulativeSeconds, 20 * 60, "Should have gained less than 20 minutes")

        print("Cumulative change (Dec 21 - Jan 4): \(cumulativeSeconds) seconds (\(cumulativeSeconds / 60)m \(cumulativeSeconds % 60)s)")
    }

    // MARK: - Velocity Tests

    func testDaylightVelocity() {
        let calendar = Calendar.current
        var components = DateComponents()

        // Test at spring equinox (peak velocity for gaining daylight)
        components.year = 2025
        components.month = 3
        components.day = 20
        let springEquinox = calendar.date(from: components)!

        guard let equinoxVelocity = SolarCalculator.daylightVelocity(for: springEquinox, at: minneapolis) else {
            XCTFail("Failed to calculate velocity at equinox")
            return
        }

        // At equinox, velocity should be at maximum (around 2-3 minutes per day)
        XCTAssertGreaterThan(abs(equinoxVelocity), 120, "Velocity at equinox should be > 2 min/day")

        // Test at summer solstice (minimum velocity)
        components.month = 6
        components.day = 21
        let summerSolstice = calendar.date(from: components)!

        guard let solsticeVelocity = SolarCalculator.daylightVelocity(for: summerSolstice, at: minneapolis) else {
            XCTFail("Failed to calculate velocity at solstice")
            return
        }

        // At solstice, velocity should be near zero
        XCTAssertLessThan(abs(solsticeVelocity), 60, "Velocity at solstice should be < 1 min/day")

        print("Velocity at spring equinox: \(equinoxVelocity) seconds/day")
        print("Velocity at summer solstice: \(solsticeVelocity) seconds/day")
    }

    // MARK: - SolsticeInfo Countdown Tests

    func testDaysSinceSolstice() {
        let calendar = Calendar.current
        var components = DateComponents()

        // January 10, 2025 - should be ~20 days after winter solstice
        components.year = 2025
        components.month = 1
        components.day = 10
        let testDate = calendar.date(from: components)!

        let solsticeInfo = SolsticeInfo(for: testDate)
        let daysSince = solsticeInfo.daysSinceSolstice(from: testDate)

        // Winter solstice 2024 is Dec 21, so Jan 10 is 20 days later
        assertIntEqual(daysSince, 20, accuracy: 1, "Should be ~20 days since winter solstice")

        print("Days since solstice (Jan 10): \(daysSince)")
    }

    func testDaysUntilEquinox() {
        let calendar = Calendar.current
        var components = DateComponents()

        // February 1, 2025 - should be ~47 days until spring equinox (Mar 20)
        components.year = 2025
        components.month = 2
        components.day = 1
        let testDate = calendar.date(from: components)!

        let solsticeInfo = SolsticeInfo(for: testDate)

        if let equinoxInfo = solsticeInfo.daysUntilEquinox(from: testDate) {
            XCTAssertEqual(equinoxInfo.type, .spring, "Next equinox should be spring")
            assertIntEqual(equinoxInfo.days, 47, accuracy: 2, "Should be ~47 days until spring equinox")

            print("Days until \(equinoxInfo.type) equinox: \(equinoxInfo.days)")
        } else {
            XCTFail("Should calculate days until equinox")
        }
    }

    func testDaysUntilSolstice() {
        let calendar = Calendar.current
        var components = DateComponents()

        // April 1, 2025 - should be ~81 days until summer solstice (Jun 21)
        components.year = 2025
        components.month = 4
        components.day = 1
        let testDate = calendar.date(from: components)!

        let solsticeInfo = SolsticeInfo(for: testDate)

        if let solsticeResult = solsticeInfo.daysUntilSolstice(from: testDate) {
            XCTAssertEqual(solsticeResult.type, .summer, "Next solstice should be summer")
            assertIntEqual(solsticeResult.days, 81, accuracy: 2, "Should be ~81 days until summer solstice")

            print("Days until \(solsticeResult.type) solstice: \(solsticeResult.days)")
        } else {
            XCTFail("Should calculate days until solstice")
        }
    }

    func testProgressThroughHalfYear() {
        let calendar = Calendar.current
        var components = DateComponents()

        // Test shortly after winter solstice - progress should be near 0
        // Use Dec 25 to be clearly in the "gaining daylight" period
        components.year = 2024
        components.month = 12
        components.day = 25
        let afterWinterSolstice = calendar.date(from: components)!

        let winterInfo = SolsticeInfo(for: afterWinterSolstice)
        let winterProgress = winterInfo.progressThroughHalfYear(for: afterWinterSolstice)
        assertDoubleEqual(winterProgress, 0.02, accuracy: 0.05, "Progress shortly after winter solstice should be ~2%")

        // Test at spring equinox - progress should be ~50%
        components.year = 2025
        components.month = 3
        components.day = 20
        let springEquinox = calendar.date(from: components)!

        let springInfo = SolsticeInfo(for: springEquinox)
        let springProgress = springInfo.progressThroughHalfYear(for: springEquinox)
        assertDoubleEqual(springProgress, 0.5, accuracy: 0.1, "Progress at spring equinox should be ~50%")

        // Test near summer solstice - progress should be near 100%
        // Use Jun 20 to be just before the solstice
        components.month = 6
        components.day = 20
        let nearSummerSolstice = calendar.date(from: components)!

        let summerInfo = SolsticeInfo(for: nearSummerSolstice)
        let summerProgress = summerInfo.progressThroughHalfYear(for: nearSummerSolstice)
        assertDoubleEqual(summerProgress, 0.99, accuracy: 0.05, "Progress near summer solstice should be ~99%")

        print("Progress after winter solstice (Dec 25): \(Int(winterProgress * 100))%")
        print("Progress at spring equinox: \(Int(springProgress * 100))%")
        print("Progress near summer solstice (Jun 20): \(Int(summerProgress * 100))%")
    }

    // MARK: - Equinox Edge Case Tests

    func testEquinoxDaylight() {
        // At equinox, day and night should be approximately equal (~12 hours)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2025
        components.month = 3
        components.day = 20
        let springEquinox = calendar.date(from: components)!

        guard let daylight = SolarCalculator.calculateDaylight(for: springEquinox, at: minneapolis) else {
            XCTFail("Failed to calculate equinox daylight")
            return
        }

        // Expected: ~12 hours (720 minutes), allow 15 minute tolerance
        let expectedMinutes = 720
        assertIntEqual(daylight.daylightMinutes, expectedMinutes, accuracy: 15,
                      "Equinox daylight should be approximately 12 hours")

        print("Spring Equinox (Mar 20, 2025):")
        print("  Duration: \(daylight.daylightMinutes) minutes (\(daylight.formattedDuration))")
    }

    // MARK: - Recent History Tests

    func testRecentHistory() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        let testDate = calendar.date(from: components)!

        let history = SolarCalculator.recentHistory(days: 7, endingOn: testDate, at: minneapolis)

        // Should have 7 days of history
        XCTAssertEqual(history.count, 7, "Should have 7 days of history")

        // All changes should be positive (gaining daylight in January)
        for entry in history {
            XCTAssertGreaterThanOrEqual(entry.changeSeconds, 0,
                                        "Should be gaining daylight each day in January")
        }

        // Most recent entry should be the test date
        if let mostRecent = history.last {
            let mostRecentDay = calendar.component(.day, from: mostRecent.date)
            XCTAssertEqual(mostRecentDay, 15, "Most recent entry should be Jan 15")
        }

        print("Recent history (7 days ending Jan 15):")
        for entry in history {
            let day = calendar.component(.day, from: entry.date)
            print("  Jan \(day): +\(entry.changeSeconds) seconds")
        }
    }

    // MARK: - Different Latitude Tests

    func testEquatorDaylight() {
        // At the equator, daylight should be ~12 hours year-round
        let equator = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let calendar = Calendar.current
        var components = DateComponents()

        // Test winter solstice
        components.year = 2024
        components.month = 12
        components.day = 21
        let winterSolstice = calendar.date(from: components)!

        guard let winterDaylight = SolarCalculator.calculateDaylight(for: winterSolstice, at: equator) else {
            XCTFail("Failed to calculate equator winter daylight")
            return
        }

        // Test summer solstice
        components.year = 2025
        components.month = 6
        components.day = 21
        let summerSolstice = calendar.date(from: components)!

        guard let summerDaylight = SolarCalculator.calculateDaylight(for: summerSolstice, at: equator) else {
            XCTFail("Failed to calculate equator summer daylight")
            return
        }

        // Both should be ~12 hours
        assertIntEqual(winterDaylight.daylightMinutes, 720, accuracy: 15,
                      "Equator winter daylight should be ~12 hours")
        assertIntEqual(summerDaylight.daylightMinutes, 720, accuracy: 15,
                      "Equator summer daylight should be ~12 hours")

        // Difference between seasons should be minimal
        let difference = abs(winterDaylight.daylightMinutes - summerDaylight.daylightMinutes)
        XCTAssertLessThan(difference, 10, "Equator daylight should vary minimally between seasons")

        print("Equator winter daylight: \(winterDaylight.daylightMinutes) minutes")
        print("Equator summer daylight: \(summerDaylight.daylightMinutes) minutes")
    }
}

// Helper for approximate equality
extension XCTestCase {
    func assertIntEqual(_ actual: Int, _ expected: Int, accuracy: Int, _ message: String) {
        XCTAssertTrue(abs(actual - expected) <= accuracy,
                     "\(message) - Expected \(expected) ± \(accuracy), got \(actual)")
    }

    func assertDoubleEqual(_ actual: Double, _ expected: Double, accuracy: Double, _ message: String) {
        XCTAssertTrue(abs(actual - expected) <= accuracy,
                     "\(message) - Expected \(expected) ± \(accuracy), got \(actual)")
    }
}
