import Foundation
import CoreLocation
import Combine

// @MainActor ensures all UI updates happen on the main thread
@MainActor
class AppViewModel: ObservableObject {
    
    // MARK: - Published Properties
    // Any view watching this ViewModel will automatically update
    // when these values change
    
    @Published var isOnboarded: Bool = false
    @Published var natalChart: NatalChart? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Onboarding Form State
    // These hold the values the user types in the onboarding form
    @Published var birthDate: Date = Calendar.current.date(
        byAdding: .year, value: -30, to: Date()) ?? Date()
    @Published var birthTime: Date = Date()
    @Published var birthCity: String = ""
    
    // MARK: - Dependencies
    private let transitEngine = TransitEngine()
    private let geocoder = CLGeocoder()
    private let storageKey = "natal_chart_data"
    
    // MARK: - Init
    init() {
        loadSavedChart()
    }
    
    // MARK: - Onboarding Submission
    // Called when user taps "Calculate My Chart"
    func submitBirthData() async {
        guard !birthCity.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a birth city."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Step 1: Convert city name → coordinates
            let location = try await geocodeCity(birthCity)
            
            // Step 2: Build BirthData
            let birthData = BirthData(
                birthDate: birthDate,
                birthTime: birthTime,
                birthCity: birthCity,
                latitude: location.latitude,
                longitude: location.longitude,
                timezone: TimeZone.current
            )
            
            // Step 3: Calculate the natal chart
            let chart = transitEngine.buildNatalChart(from: birthData)
            
            // Step 4: Save and update state
            natalChart = chart
            saveChart(chart)
            isOnboarded = true
            
        } catch {
            errorMessage = "Could not find \"\(birthCity)\". Please check the spelling and try again."
        }
        
        isLoading = false
    }
    
    // MARK: - Geocoding
    // Converts a city name into latitude/longitude using Apple's built-in geocoder
    private func geocodeCity(_ city: String) async throws -> CLLocationCoordinate2D {
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(city) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let coordinate = placemarks?.first?.location?.coordinate else {
                    continuation.resume(throwing: GeocodingError.notFound)
                    return
                }
                continuation.resume(returning: coordinate)
            }
        }
    }
    
    // MARK: - Persistence
    // Save/load the natal chart using UserDefaults so it survives app restarts
    
    private func saveChart(_ chart: NatalChart) {
        if let encoded = try? JSONEncoder().encode(chart) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadSavedChart() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let chart = try? JSONDecoder().decode(NatalChart.self, from: data)
        else { return }
        
        natalChart = chart
        isOnboarded = true
    }
    
    // MARK: - Reset
    func resetChart() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        natalChart = nil
        isOnboarded = false
        birthCity = ""
    }
}

// MARK: - Custom Errors
enum GeocodingError: LocalizedError {
    case notFound
    var errorDescription: String? {
        "Location not found. Please try a different city name."
    }
}
