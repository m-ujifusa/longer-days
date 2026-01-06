import SwiftUI
import CoreLocation

struct LocationPickerView: View {
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) var dismiss

    @State private var manualAddress = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            Form {
                // Current Location Option
                Section {
                    Button {
                        locationManager.requestCurrentLocation()
                    } label: {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)

                            Text("Use Current Location")
                                .foregroundColor(.primary)

                            Spacer()

                            if locationManager.isLoading && !locationManager.isManualLocation {
                                ProgressView()
                            } else if locationManager.hasLocation && !locationManager.isManualLocation {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .disabled(locationManager.authorizationStatus == .denied ||
                              locationManager.authorizationStatus == .restricted)
                } header: {
                    Text("Automatic")
                } footer: {
                    if locationManager.authorizationStatus == .denied {
                        Text("Location access is denied. Please enable it in Settings or enter your location manually below.")
                            .foregroundColor(.orange)
                    }
                }

                // Manual Entry
                Section {
                    TextField("City, State or Zip Code", text: $manualAddress)
                        .textContentType(.fullStreetAddress)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            searchLocation()
                        }

                    Button {
                        searchLocation()
                    } label: {
                        HStack {
                            Text("Search")
                            Spacer()
                            if locationManager.isLoading && manualAddress.isEmpty == false {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(manualAddress.trimmingCharacters(in: .whitespaces).isEmpty)
                } header: {
                    Text("Enter Manually")
                } footer: {
                    Text("Enter a city name (e.g., \"Minneapolis, MN\") or zip code.")
                }

                // Current Location Display
                if locationManager.hasLocation {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(locationManager.locationName)
                                    .font(.headline)

                                Spacer()

                                if locationManager.isManualLocation {
                                    Text("Manual")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }

                            if let location = locationManager.currentLocation {
                                Text("Coordinates: \(String(format: "%.4f°, %.4f°", location.latitude, location.longitude))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        Text("Selected Location")
                    }
                }

                // Error Display
                if let errorMessage = locationManager.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle("Set Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(!locationManager.hasLocation)
                }
            }
        }
    }

    private func searchLocation() {
        let trimmed = manualAddress.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        Task {
            await locationManager.setManualLocation(from: trimmed)
        }
    }
}

#Preview {
    LocationPickerView()
        .environmentObject(LocationManager())
}
