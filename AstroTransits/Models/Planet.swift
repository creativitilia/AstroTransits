import Foundation

// Every planet in our system has a name and a symbolic meaning
enum PlanetName: String, CaseIterable, Codable {
    case sun = "Sun"
    case moon = "Moon"
    case mercury = "Mercury"
    case venus = "Venus"
    case mars = "Mars"
    case jupiter = "Jupiter"
    case saturn = "Saturn"
    case uranus = "Uranus"
    case neptune = "Neptune"
    case pluto = "Pluto"
    
    // How important is this planet for transit scoring?
    var importance: Int {
        switch self {
        case .pluto:   return 7
        case .neptune: return 6
        case .uranus:  return 6
        case .saturn:  return 5
        case .jupiter: return 4
        case .sun:     return 3
        case .mars:    return 3
        case .venus:   return 2
        case .mercury: return 2
        case .moon:    return 1
        }
    }
    
    // What does this planet symbolize?
    var meaning: String {
        switch self {
        case .sun:     return "identity, ego, and life purpose"
        case .moon:    return "emotions, instincts, and inner needs"
        case .mercury: return "communication, thought, and information"
        case .venus:   return "relationships, beauty, and attraction"
        case .mars:    return "action, drive, and conflict"
        case .jupiter: return "expansion, growth, and abundance"
        case .saturn:  return "restriction, responsibility, and structure"
        case .uranus:  return "sudden change, rebellion, and innovation"
        case .neptune: return "dreams, illusion, and spirituality"
        case .pluto:   return "transformation, power, and deep change"
        }
    }
    
    // A simple emoji symbol for display
    var symbol: String {
        switch self {
        case .sun:     return "☉"
        case .moon:    return "☽"
        case .mercury: return "☿"
        case .venus:   return "♀"
        case .mars:    return "♂"
        case .jupiter: return "♃"
        case .saturn:  return "♄"
        case .uranus:  return "♅"
        case .neptune: return "♆"
        case .pluto:   return "♇"
        }
    }
}

// A planet's actual position in the sky (in degrees 0–360)
struct Planet: Identifiable, Codable {
    let id: UUID
    let name: PlanetName
    var degree: Double      // 0–360, where in the zodiac it sits
    var isRetrograde: Bool  // Is the planet moving backwards? (visual effect)
    
    init(name: PlanetName, degree: Double, isRetrograde: Bool = false) {
        self.id = UUID()
        self.name = name
        self.degree = degree
        self.isRetrograde = isRetrograde
    }
    
    // Which zodiac sign is this degree in?
    var zodiacSign: String {
        let signs = ["Aries","Taurus","Gemini","Cancer","Leo","Virgo",
                     "Libra","Scorpio","Sagittarius","Capricorn","Aquarius","Pisces"]
        let index = Int(degree / 30) % 12
        return signs[index]
    }
    
    // Degrees within that sign (0–29)
    var degreeInSign: Double {
        return degree.truncatingRemainder(dividingBy: 30)
    }
}
