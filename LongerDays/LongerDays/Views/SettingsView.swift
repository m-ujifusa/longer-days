import SwiftUI
import CoreLocation

struct SettingsView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var userPreferences: UserPreferences
    @Environment(\.dismiss) var dismiss

    @StateObject private var notificationManager = NotificationManager()
    @State private var showLocationPicker = false
    @State private var previewMessage = ""
    @State private var scheduledNotificationCount = 0

    var body: some View {
        NavigationView {
            Form {
                // Location Section
                Section {
                    locationRow
                } header: {
                    Text("Location")
                } footer: {
                    Text("Your location is used to calculate accurate sunrise and sunset times.")
                }

                // Notification Time Section
                Section {
                    Toggle("Notify at sunrise", isOn: $userPreferences.notifyAtSunrise)

                    if !userPreferences.notifyAtSunrise {
                        DatePicker(
                            "Notification time",
                            selection: $userPreferences.customNotificationTime,
                            displayedComponents: .hourAndMinute
                        )
                    }

                    if let nextNotification = notificationManager.formattedNextNotification {
                        HStack {
                            Text("Next notification")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(nextNotification)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("Scheduled notifications")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(scheduledNotificationCount) days")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Notification Time")
                }

                // Notification Content Section
                Section {
                    Toggle("Show daily change", isOn: $userPreferences.showDailyChange)
                        .onChange(of: userPreferences.showDailyChange) { _, newValue in
                            validateContentToggles(showDaily: newValue, showCumulative: userPreferences.showChangeSinceSolstice)
                        }

                    Toggle("Show change since solstice", isOn: $userPreferences.showChangeSinceSolstice)
                        .onChange(of: userPreferences.showChangeSinceSolstice) { _, newValue in
                            validateContentToggles(showDaily: userPreferences.showDailyChange, showCumulative: newValue)
                        }
                } header: {
                    Text("Notification Content")
                } footer: {
                    Text("At least one option must be enabled.")
                }

                // Summer Mode Section
                Section {
                    Toggle("Pause after summer solstice", isOn: $userPreferences.pauseAfterSummerSolstice)
                } header: {
                    Text("Summer Mode")
                } footer: {
                    Text("Notifications will pause after June 21 and resume automatically at the winter solstice.")
                }

                // Preview Section
                if locationManager.hasLocation {
                    Section {
                        Text(previewMessage)
                            .font(.callout)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("Notification Preview")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView()
                    .environmentObject(locationManager)
            }
            .onAppear {
                updatePreview()
                scheduleNotification()
                updateNotificationCount()
            }
            .onChange(of: locationManager.locationName) { _, _ in
                updatePreview()
                scheduleNotification()
            }
            .onChange(of: userPreferences.showDailyChange) { _, _ in
                updatePreview()
            }
            .onChange(of: userPreferences.showChangeSinceSolstice) { _, _ in
                updatePreview()
            }
            .onChange(of: userPreferences.notifyAtSunrise) { _, _ in
                scheduleNotification()
            }
            .onChange(of: userPreferences.customNotificationTime) { _, _ in
                scheduleNotification()
            }
        }
    }

    // MARK: - Views

    private var locationRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if locationManager.hasLocation {
                    Text(locationManager.locationName.isEmpty ? "Location Set" : locationManager.locationName)
                        .font(.body)

                    if let location = locationManager.currentLocation {
                        Text(String(format: "%.4f°, %.4f°", location.latitude, location.longitude))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No location set")
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if locationManager.isLoading {
                ProgressView()
            } else {
                Button(locationManager.hasLocation ? "Change" : "Set Location") {
                    showLocationPicker = true
                }
            }
        }
    }

    // MARK: - Methods

    private func validateContentToggles(showDaily: Bool, showCumulative: Bool) {
        if !showDaily && !showCumulative {
            if !userPreferences.showDailyChange {
                userPreferences.showDailyChange = true
            } else {
                userPreferences.showChangeSinceSolstice = true
            }
        }
    }

    private func updatePreview() {
        guard let location = locationManager.currentLocation else {
            previewMessage = "Set your location to see a preview."
            return
        }

        previewMessage = notificationManager.generatePreviewMessage(
            for: Date(),
            at: location,
            preferences: userPreferences
        )
    }

    private func scheduleNotification() {
        Task {
            await notificationManager.scheduleNextNotification(
                preferences: userPreferences,
                location: locationManager.currentLocation
            )
            await updateNotificationCount()
        }
    }

    private func updateNotificationCount() {
        Task {
            let count = await notificationManager.getPendingNotificationCount()
            await MainActor.run {
                scheduledNotificationCount = count
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(LocationManager())
        .environmentObject(UserPreferences())
}
