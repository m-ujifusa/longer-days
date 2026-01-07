import SwiftUI
import CoreLocation

struct MainView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var userPreferences: UserPreferences

    @State private var showSettings = false

    // Computed solar data
    @State private var daylightInfo: SolarCalculator.DaylightInfo?
    @State private var cumulativeChangeSeconds: Int = 0
    @State private var dailyChangeSeconds: Int = 0
    @State private var velocitySeconds: Int = 0
    @State private var progress: Double = 0
    @State private var isGainingDaylight: Bool = true
    @State private var recentSolsticeType: SolsticeInfo.SolsticeType = .winter
    @State private var daysSinceSolstice: Int = 0
    @State private var daysUntilEquinox: Int? = nil
    @State private var nextEquinoxType: SolsticeInfo.EquinoxType? = nil
    @State private var daysUntilSolstice: Int? = nil
    @State private var nextSolsticeType: SolsticeInfo.SolsticeType? = nil
    @State private var peakVelocitySeconds: Int = 0
    @State private var peakDate: Date = Date()

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()

                if locationManager.hasLocation {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Compact Hero Section
                            CompactHeroView(
                                changeSeconds: cumulativeChangeSeconds,
                                progress: progress,
                                isGainingDaylight: isGainingDaylight,
                                daysSinceSolstice: daysSinceSolstice
                            )
                            .padding(.top, 20)

                            // Velocity (2nd from top)
                            VelocityView(
                                velocitySeconds: velocitySeconds,
                                peakVelocitySeconds: peakVelocitySeconds,
                                peakDate: peakDate,
                                isGainingDaylight: isGainingDaylight
                            )

                            // Sunrise/Sunset Card (Apple Weather style)
                            if let info = daylightInfo {
                                SunriseSunsetCard(
                                    sunrise: info.sunrise,
                                    sunset: info.sunset,
                                    firstLight: info.civilDawn,
                                    lastLight: info.civilDusk,
                                    daylightDuration: info.daylightDuration,
                                    currentTime: Date()
                                )
                            }

                            // Countdowns
                            CountdownsView(
                                daysSinceSolstice: daysSinceSolstice,
                                daysUntilEquinox: daysUntilEquinox,
                                daysUntilNextSolstice: daysUntilSolstice,
                                isGainingDaylight: isGainingDaylight,
                                recentSolsticeType: recentSolsticeType,
                                nextEquinoxType: nextEquinoxType,
                                nextSolsticeType: nextSolsticeType
                            )

                            // Monthly Averages (Apple Weather style)
                            if let location = locationManager.currentLocation {
                                MonthlyAveragesView(location: location)
                            }

                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                    }
                } else {
                    noLocationView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Theme.secondaryText)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(locationManager)
                    .environmentObject(userPreferences)
            }
            .onAppear {
                refreshData()
            }
            .onChange(of: locationManager.locationName) { _, _ in
                refreshData()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - No Location View

    private var noLocationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.secondaryText)

            Text("Location Required")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Theme.primaryText)

            Text("Set your location to see daylight information")
                .font(.subheadline)
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                showSettings = true
            } label: {
                Text("Set Location")
                    .font(.headline)
                    .foregroundColor(Theme.background)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Theme.accent)
                    .cornerRadius(12)
            }
        }
        .padding()
    }

    // MARK: - Data Refresh

    private func refreshData() {
        guard let location = locationManager.currentLocation else { return }

        let today = Date()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Get daylight info
        daylightInfo = SolarCalculator.calculateDaylight(for: today, at: location)

        // Get solstice info
        let solsticeInfo = SolsticeInfo(for: today)
        let (recentSolstice, solsticeType) = solsticeInfo.mostRecentSolstice(before: today)
        recentSolsticeType = solsticeType
        isGainingDaylight = solsticeInfo.season(for: today) == .gainingDaylight

        // Calculate cumulative change
        cumulativeChangeSeconds = SolarCalculator.cumulativeDaylightChangeSeconds(
            since: recentSolstice,
            to: today,
            at: location
        ) ?? 0

        // Calculate daily change
        dailyChangeSeconds = SolarCalculator.dailyChangeSeconds(
            from: yesterday,
            to: today,
            at: location
        ) ?? 0

        // Calculate velocity (use daily change - today vs yesterday)
        velocitySeconds = dailyChangeSeconds

        // Calculate peak velocity (at equinox)
        // Peak rate of change occurs at equinoxes
        if isGainingDaylight {
            peakDate = solsticeInfo.springEquinox
        } else {
            peakDate = solsticeInfo.fallEquinox
        }
        peakVelocitySeconds = abs(SolarCalculator.daylightVelocity(for: peakDate, at: location) ?? 200)

        // Get progress through half-year
        progress = solsticeInfo.progressThroughHalfYear(for: today)

        // Get countdowns
        daysSinceSolstice = solsticeInfo.daysSinceSolstice(from: today)

        if let equinox = solsticeInfo.daysUntilEquinox(from: today) {
            daysUntilEquinox = equinox.days
            nextEquinoxType = equinox.type
        }

        if let solstice = solsticeInfo.daysUntilSolstice(from: today) {
            daysUntilSolstice = solstice.days
            nextSolsticeType = solstice.type
        }
    }

}

#Preview {
    MainView()
        .environmentObject(LocationManager())
        .environmentObject(UserPreferences())
}
