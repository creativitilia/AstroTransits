import Foundation

// A transit = a current planet forming an aspect to a natal planet
struct Transit: Identifiable {
    let id: UUID
    let transitPlanet: Planet       // The planet moving through the sky NOW
    let natalPlanet: Planet         // The planet from the birth chart
    let aspect: AspectType          // The angle between them
    let orb: Double                 // How many degrees off from exact? (0–3)
    let score: Int                  // Calculated importance score
    let interpretation: String      // Human-readable meaning
    
    init(transitPlanet: Planet,
         natalPlanet: Planet,
         aspect: AspectType,
         orb: Double) {
        self.id = UUID()
        self.transitPlanet = transitPlanet
        self.natalPlanet = natalPlanet
        self.aspect = aspect
        self.orb = orb
        self.score = Transit.calculateScore(
            transitPlanet: transitPlanet,
            aspect: aspect,
            orb: orb
        )
        self.interpretation = Transit.buildInterpretation(
            transitPlanet: transitPlanet,
            natalPlanet: natalPlanet,
            aspect: aspect
        )
    }
    
    // A readable title like "Saturn □ Moon"
    var title: String {
        "\(transitPlanet.name.rawValue) \(aspect.symbol) \(natalPlanet.name.rawValue)"
    }
    
    // Orb displayed as a string like "1.2°"
    var orbDisplay: String {
        String(format: "%.1f°", orb)
    }
    
    // MARK: - Scoring
    
    static func calculateScore(transitPlanet: Planet,
                                aspect: AspectType,
                                orb: Double) -> Int {
        let planetScore = transitPlanet.name.importance
        let aspectScore = aspect.importance
        
        let orbScore: Int
        if orb < 0.5 {
            orbScore = 3
        } else if orb < 1.0 {
            orbScore = 2
        } else if orb < 2.0 {
            orbScore = 1
        } else {
            orbScore = 0
        }
        
        return planetScore + aspectScore + orbScore
    }
    
    // MARK: - Interpretation Builder
    
    static func buildInterpretation(transitPlanet: Planet,
                                     natalPlanet: Planet,
                                     aspect: AspectType) -> String {
        let transitMeaning = transitPlanet.name.meaning
        let natalMeaning   = natalPlanet.name.meaning
        let aspectTone     = aspect.tone
        
        switch aspect {
        case .conjunction:
            return "The energy of \(transitMeaning) merges directly with your natal sense of \(natalMeaning). This can feel intensifying — a spotlight on both themes at once."
            
        case .square:
            return "There is \(aspectTone) between \(transitMeaning) and your natal \(natalMeaning). This may feel like friction or pressure, but it often catalyzes important growth."
            
        case .opposition:
            return "You may experience \(aspectTone) involving \(transitMeaning) pulling against your natal \(natalMeaning). Balance and awareness of both sides will help."
            
        case .trine:
            return "A flow of \(aspectTone) connects \(transitMeaning) with your natal \(natalMeaning). This is a supportive energy that makes things come more naturally."
            
        case .sextile:
            return "There is \(aspectTone) between \(transitMeaning) and your natal \(natalMeaning). With a little effort, this energy can open helpful doors."
        }
    }
}
