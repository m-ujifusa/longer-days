import Foundation
import Combine

class UserPreferences: ObservableObject {
    private let userDefaults = UserDefaults.standard

    // Keys
    private enum Keys {
        static let notifyAtSunrise = "notifyAtSunrise"
        static let customNotificationTime = "customNotificationTime"
        static let showChangeSinceSolstice = "showChangeSinceSolstice"
        static let showDailyChange = "showDailyChange"
        static let pauseAfterSummerSolstice = "pauseAfterSummerSolstice"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    // MARK: - Published Properties

    @Published var notifyAtSunrise: Bool {
        didSet {
            userDefaults.set(notifyAtSunrise, forKey: Keys.notifyAtSunrise)
            preferencesDidChange()
        }
    }

    @Published var customNotificationTime: Date {
        didSet {
            userDefaults.set(customNotificationTime, forKey: Keys.customNotificationTime)
            preferencesDidChange()
        }
    }

    @Published var showChangeSinceSolstice: Bool {
        didSet {
            userDefaults.set(showChangeSinceSolstice, forKey: Keys.showChangeSinceSolstice)
            preferencesDidChange()
        }
    }

    @Published var showDailyChange: Bool {
        didSet {
            userDefaults.set(showDailyChange, forKey: Keys.showDailyChange)
            preferencesDidChange()
        }
    }

    @Published var pauseAfterSummerSolstice: Bool {
        didSet {
            userDefaults.set(pauseAfterSummerSolstice, forKey: Keys.pauseAfterSummerSolstice)
            preferencesDidChange()
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            userDefaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        }
    }

    // Callback for when preferences change
    var onPreferencesChanged: (() -> Void)?

    // MARK: - Initialization

    init() {
        // Load saved preferences or use defaults
        self.notifyAtSunrise = userDefaults.object(forKey: Keys.notifyAtSunrise) as? Bool ?? true
        self.showChangeSinceSolstice = userDefaults.object(forKey: Keys.showChangeSinceSolstice) as? Bool ?? true
        self.showDailyChange = userDefaults.object(forKey: Keys.showDailyChange) as? Bool ?? true
        self.pauseAfterSummerSolstice = userDefaults.object(forKey: Keys.pauseAfterSummerSolstice) as? Bool ?? false
        self.hasCompletedOnboarding = userDefaults.bool(forKey: Keys.hasCompletedOnboarding)

        // Default notification time: 7:00 AM
        if let savedTime = userDefaults.object(forKey: Keys.customNotificationTime) as? Date {
            self.customNotificationTime = savedTime
        } else {
            var components = DateComponents()
            components.hour = 7
            components.minute = 0
            self.customNotificationTime = Calendar.current.date(from: components) ?? Date()
        }
    }

    // MARK: - Validation

    /// Ensure at least one content option is enabled
    func validateContentOptions() -> Bool {
        return showChangeSinceSolstice || showDailyChange
    }

    /// Get the notification time for a specific date (sunrise or custom)
    func getNotificationTime(for date: Date, sunriseTime: Date?) -> Date {
        if notifyAtSunrise, let sunrise = sunriseTime {
            return sunrise
        }

        // Use custom time but on the specified date
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: customNotificationTime)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute

        return calendar.date(from: dateComponents) ?? date
    }

    private func preferencesDidChange() {
        onPreferencesChanged?()
    }
}

// MARK: - Notification Content Configuration

extension UserPreferences {
    struct NotificationContent {
        let showDaily: Bool
        let showCumulative: Bool
    }

    var notificationContent: NotificationContent {
        NotificationContent(
            showDaily: showDailyChange,
            showCumulative: showChangeSinceSolstice
        )
    }
}
