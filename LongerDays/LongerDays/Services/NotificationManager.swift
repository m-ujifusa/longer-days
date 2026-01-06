import Foundation
import UserNotifications
import CoreLocation

class NotificationManager: ObservableObject {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let daylightDataManager = DaylightDataManager()

    private let notificationIdentifier = "dailyDaylightNotification"

    @Published var isAuthorized: Bool = false
    @Published var lastScheduledDate: Date?

    init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                isAuthorized = granted
            }
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Notification Scheduling

    func scheduleNextNotification(preferences: UserPreferences, location: CLLocationCoordinate2D?) async {
        guard let location = location else { return }

        // Cancel any existing notifications
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])

        let now = Date()
        let calendar = Calendar.current

        // Determine which day to schedule for
        var targetDate: Date
        var notificationDate: Date

        if preferences.notifyAtSunrise {
            // For sunrise, always schedule tomorrow's sunrise
            targetDate = calendar.date(byAdding: .day, value: 1, to: now)!
            if let daylightInfo = SolarCalculator.calculateDaylight(for: targetDate, at: location) {
                notificationDate = daylightInfo.sunrise
            } else {
                notificationDate = targetDate
            }
        } else {
            // For custom time, build today's notification time directly
            let customTime = preferences.customNotificationTime
            let timeComponents = calendar.dateComponents([.hour, .minute], from: customTime)

            var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
            todayComponents.hour = timeComponents.hour
            todayComponents.minute = timeComponents.minute
            todayComponents.second = 0

            let todayNotificationTime = calendar.date(from: todayComponents) ?? now

            if todayNotificationTime > now {
                // Schedule for today
                targetDate = now
                notificationDate = todayNotificationTime
            } else {
                // Schedule for tomorrow
                targetDate = calendar.date(byAdding: .day, value: 1, to: now)!
                var tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
                tomorrowComponents.hour = timeComponents.hour
                tomorrowComponents.minute = timeComponents.minute
                tomorrowComponents.second = 0
                notificationDate = calendar.date(from: tomorrowComponents) ?? targetDate
            }
        }

        // Check if notifications should be paused (summer mode)
        let solsticeInfo = SolsticeInfo(for: targetDate)
        if solsticeInfo.shouldPauseForSummer(date: targetDate, summerModeEnabled: preferences.pauseAfterSummerSolstice) {
            await MainActor.run {
                lastScheduledDate = nil
            }
            return
        }

        // Calculate notification content
        guard let content = buildNotificationContent(for: targetDate, at: location, preferences: preferences) else {
            return
        }

        // Create trigger
        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )

        let scheduledDate = notificationDate
        do {
            try await notificationCenter.add(request)
            await MainActor.run {
                lastScheduledDate = scheduledDate
            }

            // Store today's data for comparison
            if let todayInfo = daylightDataManager.calculateDaylightInfo(for: now, at: location) {
                daylightDataManager.storeDaylightData(todayInfo.current)
            }
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    var formattedNextNotification: String? {
        guard let date = lastScheduledDate else { return nil }

        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tomorrow at' h:mm a"
        } else {
            formatter.dateFormat = "MMM d 'at' h:mm a"
        }

        return formatter.string(from: date)
    }

    // MARK: - Content Building

    private func buildNotificationContent(for date: Date, at location: CLLocationCoordinate2D, preferences: UserPreferences) -> UNMutableNotificationContent? {
        let content = UNMutableNotificationContent()
        content.sound = .default

        // Check for solstice
        let solsticeInfo = SolsticeInfo(for: date)
        if let solsticeType = solsticeInfo.isSolstice(date) {
            content.title = SolsticeInfo.solsticeEmoji(for: solsticeType)
            content.body = SolsticeInfo.solsticeMessage(for: solsticeType)
            return content
        }

        // Calculate daylight comparison
        guard let (_, comparison) = daylightDataManager.calculateDaylightInfo(for: date, at: location),
              let comp = comparison else {
            // First launch - no previous data
            if let daylightInfo = SolarCalculator.calculateDaylight(for: date, at: location) {
                content.title = "☀️ Today's Daylight"
                content.body = "You have \(daylightInfo.formattedDuration) of daylight today."
                return content
            }
            return nil
        }

        // Build notification based on preferences
        let emoji = comp.emoji
        var parts: [String] = []

        if preferences.showDailyChange {
            parts.append(comp.dailyChangeFormatted)
        }

        if preferences.showChangeSinceSolstice {
            parts.append(comp.cumulativeChangeFormatted)
        }

        if parts.isEmpty {
            return nil
        }

        content.title = "\(emoji) Daylight Update"
        content.body = parts.joined(separator: " | ")

        return content
    }

    // MARK: - Testing / Preview

    func generatePreviewMessage(for date: Date, at location: CLLocationCoordinate2D, preferences: UserPreferences) -> String {
        // Check for solstice
        let solsticeInfo = SolsticeInfo(for: date)
        if let solsticeType = solsticeInfo.isSolstice(date) {
            return "\(SolsticeInfo.solsticeEmoji(for: solsticeType)) \(SolsticeInfo.solsticeMessage(for: solsticeType))"
        }

        // Calculate comparison
        guard let (_, comparison) = daylightDataManager.calculateDaylightInfo(for: date, at: location),
              let comp = comparison else {
            if let daylightInfo = SolarCalculator.calculateDaylight(for: date, at: location) {
                return "☀️ You have \(daylightInfo.formattedDuration) of daylight today."
            }
            return "Unable to calculate daylight information."
        }

        var parts: [String] = []

        if preferences.showDailyChange {
            parts.append(comp.dailyChangeFormatted)
        }

        if preferences.showChangeSinceSolstice {
            parts.append(comp.cumulativeChangeFormatted)
        }

        if parts.isEmpty {
            return "No content selected."
        }

        return parts.joined(separator: " | ")
    }
}
