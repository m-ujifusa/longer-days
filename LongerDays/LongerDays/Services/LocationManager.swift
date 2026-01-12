import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let userDefaults = UserDefaults.standard

    // Keys
    private enum Keys {
        static let latitude = "savedLatitude"
        static let longitude = "savedLongitude"
        static let locationName = "savedLocationName"
        static let isManualLocation = "isManualLocation"
    }

    // MARK: - Published Properties

    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var locationName: String = ""
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isManualLocation: Bool = false

    var hasLocation: Bool {
        currentLocation != nil
    }

    // MARK: - Initialization

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer

        loadSavedLocation()
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Public Methods

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestCurrentLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }

        isLoading = true
        errorMessage = nil
        locationManager.requestLocation()
    }

    func setManualLocation(from address: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            guard let placemark = placemarks.first,
                  let location = placemark.location else {
                await MainActor.run {
                    errorMessage = "Could not find location for \"\(address)\""
                    isLoading = false
                }
                return
            }

            let name = formatPlacemark(placemark)

            await MainActor.run {
                currentLocation = location.coordinate
                locationName = name
                isManualLocation = true
                isLoading = false
                saveLocation()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Geocoding failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    func clearLocation() {
        currentLocation = nil
        locationName = ""
        isManualLocation = false
        clearSavedLocation()
    }

    // MARK: - Private Methods

    private func saveLocation() {
        guard let location = currentLocation else { return }

        userDefaults.set(location.latitude, forKey: Keys.latitude)
        userDefaults.set(location.longitude, forKey: Keys.longitude)
        userDefaults.set(locationName, forKey: Keys.locationName)
        userDefaults.set(isManualLocation, forKey: Keys.isManualLocation)

        // Also save to shared container for widget access
        SharedDataManager.shared.saveLocation(
            latitude: location.latitude,
            longitude: location.longitude,
            name: locationName
        )
    }

    private func loadSavedLocation() {
        guard userDefaults.object(forKey: Keys.latitude) != nil else { return }

        let latitude = userDefaults.double(forKey: Keys.latitude)
        let longitude = userDefaults.double(forKey: Keys.longitude)
        let name = userDefaults.string(forKey: Keys.locationName) ?? ""
        let isManual = userDefaults.bool(forKey: Keys.isManualLocation)

        currentLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        locationName = name
        isManualLocation = isManual
    }

    private func clearSavedLocation() {
        userDefaults.removeObject(forKey: Keys.latitude)
        userDefaults.removeObject(forKey: Keys.longitude)
        userDefaults.removeObject(forKey: Keys.locationName)
        userDefaults.removeObject(forKey: Keys.isManualLocation)
    }

    private func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if error != nil {
                    self?.errorMessage = "Could not determine location name"
                    // Still save coordinates even if reverse geocoding fails
                    self?.locationName = String(format: "%.2f°, %.2f°",
                                                location.coordinate.latitude,
                                                location.coordinate.longitude)
                    self?.saveLocation()
                    return
                }

                if let placemark = placemarks?.first {
                    self?.locationName = self?.formatPlacemark(placemark) ?? ""
                    self?.saveLocation()
                }
            }
        }
    }

    private func formatPlacemark(_ placemark: CLPlacemark) -> String {
        if let city = placemark.locality, let state = placemark.administrativeArea {
            return "\(city), \(state)"
        } else if let city = placemark.locality {
            return city
        } else if let area = placemark.administrativeArea {
            return area
        } else {
            return String(format: "%.2f°, %.2f°",
                         placemark.location?.coordinate.latitude ?? 0,
                         placemark.location?.coordinate.longitude ?? 0)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            isLoading = false
            return
        }

        currentLocation = location.coordinate
        isManualLocation = false
        reverseGeocode(location: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false

        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                errorMessage = "Location access denied. Please enable in Settings or enter your location manually."
            case .locationUnknown:
                errorMessage = "Unable to determine location. Please try again or enter manually."
            default:
                errorMessage = "Location error: \(error.localizedDescription)"
            }
        } else {
            errorMessage = "Location error: \(error.localizedDescription)"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if currentLocation == nil && !isManualLocation {
                requestCurrentLocation()
            }
        case .denied, .restricted:
            if !isManualLocation {
                errorMessage = "Location access denied. Please enter your location manually."
            }
        default:
            break
        }
    }
}
