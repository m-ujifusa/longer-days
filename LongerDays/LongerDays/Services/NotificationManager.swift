import Foundation
import UserNotifications
import CoreLocation

class NotificationManager: ObservableObject {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let daylightDataManager = DaylightDataManager()

    private let notificationIdentifierPrefix = "dailyDaylightNotification"
    private let maxNotificationsToSchedule = 64 // iOS limit

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

        // Cancel any existing notifications with our prefix
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let idsToRemove = pendingRequests
            .filter { $0.identifier.hasPrefix(notificationIdentifierPrefix) }
            .map { $0.identifier }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: idsToRemove)

        let now = Date()
        let calendar = Calendar.current

        var firstScheduledDate: Date?
        var scheduledCount = 0

        // Schedule notifications starting from today, up to iOS limit
        for dayOffset in 0... {
            // Stop if we've scheduled the maximum allowed
            guard scheduledCount < maxNotificationsToSchedule else { break }

            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            // Check if notifications should be paused (summer mode)
            let solsticeInfo = SolsticeInfo(for: targetDate)
            if solsticeInfo.shouldPauseForSummer(date: targetDate, summerModeEnabled: preferences.pauseAfterSummerSolstice) {
                continue
            }

            // Determine notification time for this day
            let notificationDate: Date
            if preferences.notifyAtSunrise {
                if let daylightInfo = SolarCalculator.calculateDaylight(for: targetDate, at: location) {
                    notificationDate = daylightInfo.sunrise
                } else {
                    continue
                }
            } else {
                let customTime = preferences.customNotificationTime
                let timeComponents = calendar.dateComponents([.hour, .minute], from: customTime)

                var dayComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
                dayComponents.hour = timeComponents.hour
                dayComponents.minute = timeComponents.minute
                dayComponents.second = 0

                guard let scheduledTime = calendar.date(from: dayComponents) else { continue }
                notificationDate = scheduledTime
            }

            // Skip if the notification time has already passed
            guard notificationDate > now else { continue }

            // Build content for this specific day
            guard let content = buildNotificationContent(for: targetDate, at: location, preferences: preferences) else {
                continue
            }

            // Create trigger
            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

            // Create request with unique identifier for each day
            let identifier = "\(notificationIdentifierPrefix)-\(scheduledCount)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
                scheduledCount += 1
                if firstScheduledDate == nil {
                    firstScheduledDate = notificationDate
                }
            } catch {
                print("Failed to schedule notification for day \(dayOffset): \(error)")
            }
        }

        await MainActor.run {
            lastScheduledDate = firstScheduledDate
        }

        // Store today's data for comparison
        if let todayInfo = daylightDataManager.calculateDaylightInfo(for: now, at: location) {
            daylightDataManager.storeDaylightData(todayInfo.current)
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

    // MARK: - Preview

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
