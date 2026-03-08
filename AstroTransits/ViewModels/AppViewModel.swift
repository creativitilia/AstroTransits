import Foundation
import MapKit
import CoreLocation
import Combine

@MainActor
class AppViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isOnboarded: Bool = false
    @Published var natalChart: NatalChart? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Onboarding Form State
    @Published var birthDate: Date = Calendar.current.date(
        byAdding: .year, value: -30, to: Date()) ?? Date()
    @Published var birthTime: Date = Date()
    @Published var birthCity: String = ""
    
    // MARK: - Dependencies
    private let transitEngine = TransitEngine()
    private let storageKey = "natal_chart_data"
    
    // MARK: - Init
    init() {
        loadSavedChart()
    }
    
    // MARK: - Onboarding Submission
    func submitBirthData() async {
        guard !birthCity.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a birth city."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let location = try await geocodeCity(birthCity)
            
            let birthData = BirthData(
                birthDate: birthDate,
                birthTime: birthTime,
                birthCity: birthCity,
                latitude: location.latitude,
                longitude: location.longitude,
                timezone: TimeZone.current
            )
            
            let chart = transitEngine.buildNatalChart(from: birthData)
            
            natalChart = chart
            saveChart(chart)
            isOnboarded = true
            
        } catch {
            errorMessage = "Could not find \"\(birthCity)\". Please check the spelling and try again."
        }
        
        isLoading = false
    }
    
    // MARK: - Geocoding (iOS 26 compatible)
    private func geocodeCity(_ city: String) async throws -> CLLocationCoordinate2D {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = city
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        guard let item = response.mapItems.first else {
            throw GeocodingError.notFound
        }
        
        return item.location.coordinate
    }
    
    // MARK: - Persistence
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
