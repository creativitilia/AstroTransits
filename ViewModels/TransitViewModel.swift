import Foundation
import Combine

@MainActor
class TransitViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // The top 5 transits for the currently selected time
    @Published var activeTransits: [Transit] = []
    
    // The currently selected time (defaults to now)
    @Published var selectedDate: Date = Date()
    
    // Slider value: 0.0 = midnight, 1.0 = 23:59
    @Published var sliderValue: Double = 0.0
    
    // Which chart mode is the wheel showing?
    @Published var chartMode: ChartMode = .transits
    
    // Current transit planet positions (for the chart wheel)
    @Published var transitPlanets: [Planet] = []
    
    // MARK: - Dependencies
    private let transitEngine = TransitEngine()
    private let astronomyEngine = AstronomyEngine()
    private var cancellables = Set<AnyCancellable>()
    
    // The natal chart (injected from AppViewModel)
    var natalChart: NatalChart? {
        didSet { refreshTransits() }
    }
    
    // MARK: - Init
    init() {
        setupSliderBinding()
        setSliderToCurrentTime()
    }
    
    // MARK: - Slider → Time Binding
    // When the slider moves, update selectedDate and recalculate transits
    private func setupSliderBinding() {
        $sliderValue
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.updateTimeFromSlider(value)
            }
            .store(in: &cancellables)
    }
    
    // Set slider to current time of day on launch
    private func setSliderToCurrentTime() {
        let calendar = Calendar.current
        let now = Date()
        let hour = Double(calendar.component(.hour, from: now))
        let minute = Double(calendar.component(.minute, from: now))
        sliderValue = (hour * 60 + minute) / (24 * 60)
    }
    
    // Convert slider 0.0–1.0 into a real time today
    private func updateTimeFromSlider(_ value: Double) {
        let calendar = Calendar.current
        let today = Date()
        
        guard let startOfDay = calendar.date(
            bySettingHour: 0, minute: 0, second: 0, of: today
        ) else { return }
        
        let secondsInDay: Double = 24 * 60 * 60
        selectedDate = startOfDay.addingTimeInterval(value * secondsInDay)
        refreshTransits()
    }
    
    // MARK: - Refresh
    // Recalculate transits for the current selectedDate
    func refreshTransits() {
        guard let chart = natalChart else {
            activeTransits = []
            transitPlanets = []
            return
        }
        
        activeTransits = transitEngine.calculateTransits(
            natalChart: chart,
            for: selectedDate
        )
        
        transitPlanets = astronomyEngine.calculatePlanets(
            for: selectedDate,
            latitude: chart.birthData.latitude,
            longitude: chart.birthData.longitude
        )
    }
    
    // MARK: - Formatted Time Display
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: selectedDate)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }
    
    // MARK: - Today's Themes
    // A short summary of the dominant energies based on top transits
    var todaysThemes: String {
        guard !activeTransits.isEmpty else {
            return "The sky is relatively quiet right now."
        }
        let topTransit = activeTransits[0]
        return "\(topTransit.transitPlanet.name.rawValue) \(topTransit.aspect.rawValue) your natal \(topTransit.natalPlanet.name.rawValue) is the strongest influence today."
    }
}

// MARK: - Chart Mode
enum ChartMode: String, CaseIterable {
    case natal    = "Natal"
    case transits = "Transits"
}
