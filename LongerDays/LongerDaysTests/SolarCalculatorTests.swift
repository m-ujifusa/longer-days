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
        XCTAssertEqual(daylight.daylightMinutes, expectedMinutes, accuracy: 10,
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
        XCTAssertEqual(daylight.daylightMinutes, expectedMinutes, accuracy: 10,
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
}

// Helper for approximate equality
extension XCTestCase {
    func XCTAssertEqual(_ actual: Int, _ expected: Int, accuracy: Int, _ message: String) {
        XCTAssertTrue(abs(actual - expected) <= accuracy,
                     "\(message) - Expected \(expected) ± \(accuracy), got \(actual)")
    }
}
