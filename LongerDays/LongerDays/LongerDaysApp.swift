import SwiftUI
import UserNotifications
import BackgroundTasks
import WidgetKit

@main
struct LongerDaysApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var userPreferences = UserPreferences()

    init() {
        registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(locationManager)
                .environmentObject(notificationManager)
                .environmentObject(userPreferences)
                .onAppear {
                    requestNotificationPermission()
                    scheduleBackgroundRefresh()
                    locationManager.requestLocationPermission()
                    refreshWidgetData()
                }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                Task { @MainActor in
                    await notificationManager.scheduleNextNotification(
                        preferences: userPreferences,
                        location: locationManager.currentLocation
                    )
                }
            }
        }
    }

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.longerdays.refresh",
            using: nil
        ) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }

    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundRefresh()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task {
            // Update widget data
            refreshWidgetData()

            await notificationManager.scheduleNextNotification(
                preferences: userPreferences,
                location: locationManager.currentLocation
            )
            task.setTaskCompleted(success: true)
        }
    }

    private func refreshWidgetData() {
        guard let location = locationManager.currentLocation else { return }
        SharedDataManager.shared.updateWidgetData(
            location: location,
            locationName: locationManager.locationName
        )
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.longerdays.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // 1 hour

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background refresh: \(error)")
        }
    }
}
