import Foundation
import CoreLocation

enum MilestoneType: String, CaseIterable, Codable {
    case tenHoursDaylight = "ten_hours"
    case oneHourGained = "one_hour_gained"
    case twoHoursGained = "two_hours_gained"
    case moreLightThanDark = "more_light_than_dark"
    case earliestSunsetBehind = "earliest_sunset_behind"
    case latestSunriseBehind = "latest_sunrise_behind"
    case peakGainRate = "peak_gain_rate"

    var title: String {
        switch self {
        case .tenHoursDaylight:
            return "10 hours of daylight"
        case .oneHourGained:
            return "1 hour gained"
        case .twoHoursGained:
            return "2 hours gained"
        case .moreLightThanDark:
            return "More light than dark"
        case .earliestSunsetBehind:
            return "Earliest sunset behind us"
        case .latestSunriseBehind:
            return "Latest sunrise behind us"
        case .peakGainRate:
            return "Peak daylight gain rate"
        }
    }

    var description: String {
        switch self {
        case .tenHoursDaylight:
            return "A meaningful threshold of daylight"
        case .oneHourGained:
            return "60 minutes more than the solstice"
        case .twoHoursGained:
            return "120 minutes more than the solstice"
        case .moreLightThanDark:
            return "Spring equinox - equal day and night"
        case .earliestSunsetBehind:
            return "Sunsets getting later each day"
        case .latestSunriseBehind:
            return "Sunrises getting earlier each day"
        case .peakGainRate:
            return "Gaining daylight at maximum speed"
        }
    }
}

struct Milestone: Identifiable, Codable {
    let id: String
    let type: MilestoneType
    var isAchieved: Bool
    var achievedDate: Date?
    var targetDate: Date?
    var daysUntil: Int?

    init(type: MilestoneType, isAchieved: Bool = false, achievedDate: Date? = nil, targetDate: Date? = nil, daysUntil: Int? = nil) {
        self.id = type.rawValue
        self.type = type
        self.isAchieved = isAchieved
        self.achievedDate = achievedDate
        self.targetDate = targetDate
        self.daysUntil = daysUntil
    }
}

class MilestoneTracker: ObservableObject {
    @Published var milestones: [Milestone] = []

    private let userDefaults = UserDefaults.standard
    private let achievedMilestonesKey = "achievedMilestones"

    init() {
        loadAchievedMilestones()
    }

    func updateMilestones(for date: Date, at location: CLLocationCoordinate2D) {
        let calendar = Calendar.current
        let solsticeInfo = SolsticeInfo(for: date)
        let (recentSolstice, _) = solsticeInfo.mostRecentSolstice(before: date)
        let isGainingDaylight = solsticeInfo.season(for: date) == .gainingDaylight

        // Only show gaining milestones when gaining daylight
        guard isGainingDaylight else {
            milestones = []
            return
        }

        var updatedMilestones: [Milestone] = []

        // 10 hours of daylight milestone
        if let tenHourMilestone = calculateTenHoursMilestone(for: date, at: location, calendar: calendar) {
            updatedMilestones.append(tenHourMilestone)
        }

        // 1 hour gained milestone
        if let oneHourMilestone = calculateHoursGainedMilestone(hours: 1, for: date, at: location, since: recentSolstice, calendar: calendar) {
            updatedMilestones.append(oneHourMilestone)
        }

        // 2 hours gained milestone
        if let twoHourMilestone = calculateHoursGainedMilestone(hours: 2, for: date, at: location, since: recentSolstice, calendar: calendar) {
            updatedMilestones.append(twoHourMilestone)
        }

        // More light than dark (spring equinox)
        let equinoxMilestone = calculateEquinoxMilestone(for: date, solsticeInfo: solsticeInfo, calendar: calendar)
        updatedMilestones.append(equinoxMilestone)

        // Sort: achieved first (most recent), then upcoming (soonest first)
        updatedMilestones.sort { m1, m2 in
            if m1.isAchieved && m2.isAchieved {
                return (m1.achievedDate ?? .distantPast) > (m2.achievedDate ?? .distantPast)
            } else if m1.isAchieved {
                return true
            } else if m2.isAchieved {
                return false
            } else {
                return (m1.daysUntil ?? Int.max) < (m2.daysUntil ?? Int.max)
            }
        }

        milestones = updatedMilestones
    }

    private func calculateTenHoursMilestone(for date: Date, at location: CLLocationCoordinate2D, calendar: Calendar) -> Milestone? {
        guard let todayDaylight = SolarCalculator.calculateDaylight(for: date, at: location) else {
            return nil
        }

        let tenHoursInSeconds: TimeInterval = 10 * 3600
        let isAchieved = todayDaylight.daylightDuration >= tenHoursInSeconds

        if isAchieved {
            return Milestone(type: .tenHoursDaylight, isAchieved: true, achievedDate: date)
        }

        // Find when we'll hit 10 hours
        for dayOffset in 1...180 {
            guard let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: date),
                  let futureDaylight = SolarCalculator.calculateDaylight(for: futureDate, at: location) else {
                continue
            }
            if futureDaylight.daylightDuration >= tenHoursInSeconds {
                return Milestone(type: .tenHoursDaylight, isAchieved: false, targetDate: futureDate, daysUntil: dayOffset)
            }
        }

        return nil
    }

    private func calculateHoursGainedMilestone(hours: Int, for date: Date, at location: CLLocationCoordinate2D, since solstice: Date, calendar: Calendar) -> Milestone? {
        guard let cumulativeSeconds = SolarCalculator.cumulativeDaylightChangeSeconds(since: solstice, to: date, at: location) else {
            return nil
        }

        let targetSeconds = hours * 3600
        let milestoneType: MilestoneType = hours == 1 ? .oneHourGained : .twoHoursGained

        if cumulativeSeconds >= targetSeconds {
            return Milestone(type: milestoneType, isAchieved: true, achievedDate: date)
        }

        // Estimate days until milestone
        guard let velocity = SolarCalculator.daylightVelocity(for: date, at: location), velocity > 0 else {
            return nil
        }

        let remainingSeconds = targetSeconds - cumulativeSeconds
        let estimatedDays = remainingSeconds / velocity

        if estimatedDays > 0 && estimatedDays < 365 {
            let targetDate = calendar.date(byAdding: .day, value: estimatedDays, to: date)
            return Milestone(type: milestoneType, isAchieved: false, targetDate: targetDate, daysUntil: estimatedDays)
        }

        return nil
    }

    private func calculateEquinoxMilestone(for date: Date, solsticeInfo: SolsticeInfo, calendar: Calendar) -> Milestone {
        let springEquinox = solsticeInfo.springEquinox

        if date >= springEquinox {
            return Milestone(type: .moreLightThanDark, isAchieved: true, achievedDate: springEquinox)
        }

        let components = calendar.dateComponents([.day], from: date, to: springEquinox)
        return Milestone(type: .moreLightThanDark, isAchieved: false, targetDate: springEquinox, daysUntil: components.day)
    }

    private func loadAchievedMilestones() {
        // Load from UserDefaults if needed for persistence across sessions
    }

    private func saveAchievedMilestones() {
        // Save to UserDefaults if needed
    }
}
