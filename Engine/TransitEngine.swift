import Foundation

// MARK: - Transit Engine
// This takes a natal chart + a current time and finds all active transits.
struct TransitEngine {
    
    private let astronomyEngine = AstronomyEngine()
    
    // MARK: - Main Function
    // Returns the top 5 most important transits for a given moment
    func calculateTransits(
        natalChart: NatalChart,
        for date: Date
    ) -> [Transit] {
        
        // Step 1: Get current planet positions
        let transitPlanets = astronomyEngine.calculatePlanets(
            for: date,
            latitude: natalChart.birthData.latitude,
            longitude: natalChart.birthData.longitude
        )
        
        // Step 2: Compare each transit planet to each natal planet
        var allTransits: [Transit] = []
        
        for transitPlanet in transitPlanets {
            for natalPlanet in natalChart.planets {
                
                // Don't compare a planet to itself
                if transitPlanet.name == natalPlanet.name { continue }
                
                // Check if they form an aspect
                if let (aspect, orb) = detectAspect(from: transitPlanet.degree, to: natalPlanet.degree) {
                    let transit = Transit(
                        transitPlanet: transitPlanet,
                        natalPlanet: natalPlanet,
                        aspect: aspect,
                        orb: orb
                    )
                    allTransits.append(transit)
                }
            }
        }
        
        // Step 3: Sort by score, return top 5
        return Array(allTransits.sorted { $0.score > $1.score }.prefix(5))
    }
    
    // MARK: - Aspect Detection
    // Checks if two degrees form a recognised aspect within our orb tolerance
    func detectAspect(from degree1: Double, to degree2: Double) -> (AspectType, Double)? {
        
        // Angular separation, always 0–180
        var angle = abs(degree1 - degree2)
        if angle > 180 { angle = 360 - angle }
        
        // Check each aspect type
        for aspectType in AspectType.allCases {
            let orb = abs(angle - aspectType.angle)
            if orb <= ASPECT_ORB {
                return (aspectType, orb)
            }
        }
        
        return nil  // No aspect found
    }
    
    // MARK: - Full Chart Calculation
    // Convenience method that builds a complete NatalChart from BirthData
    func buildNatalChart(from birthData: BirthData) -> NatalChart {
        let planets = astronomyEngine.calculatePlanets(
            for: birthData.birthDateTime,
            latitude: birthData.latitude,
            longitude: birthData.longitude
        )
        
        let (ascendant, midheaven, houses) = astronomyEngine.calculateHouses(
            for: birthData.birthDateTime,
            latitude: birthData.latitude,
            longitude: birthData.longitude
        )
        
        return NatalChart(
            birthData: birthData,
            planets: planets,
            ascendant: ascendant,
            midheaven: midheaven,
            houses: houses
        )
    }
    
    // MARK: - Timeline Support
    // Generates transit snapshots across the day (for the timeline slider)
    func calculateTransitsForDay(
        natalChart: NatalChart,
        date: Date,
        intervals: Int = 24
    ) -> [(time: Date, transits: [Transit])] {
        
        let calendar = Calendar.current
        guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date) else {
            return []
        }
        
        return (0..<intervals).map { hour in
            let time = startOfDay.addingTimeInterval(Double(hour) * 3600)
            let transits = calculateTransits(natalChart: natalChart, for: time)
            return (time: time, transits: transits)
        }
    }
}
