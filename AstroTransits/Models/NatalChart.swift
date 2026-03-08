import Foundation

// Everything we need to know about a person's birth
struct BirthData: Codable {
    var birthDate: Date
    var birthTime: Date       // We'll extract the time component from this
    var birthCity: String
    var latitude: Double
    var longitude: Double
    var timezone: TimeZone
    
    // Combine date and time into one Date object
    var birthDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: birthDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: birthTime)
        
        var combined = DateComponents()
        combined.year   = dateComponents.year
        combined.month  = dateComponents.month
        combined.day    = dateComponents.day
        combined.hour   = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.timeZone = timezone
        
        return calendar.date(from: combined) ?? birthDate
    }
}

// A person's complete natal (birth) chart
struct NatalChart: Codable {
    var birthData: BirthData
    var planets: [Planet]       // All 10 planets at birth
    var ascendant: Double       // Rising sign degree (0–360)
    var midheaven: Double       // MC degree (0–360)
    var houses: [Double]        // 12 house cusp degrees
    
    // Quick lookup: get a planet by name
    func planet(_ name: PlanetName) -> Planet? {
        return planets.first { $0.name == name }
    }
    
    // Which zodiac sign is the Ascendant in?
    var ascendantSign: String {
        let signs = ["Aries","Taurus","Gemini","Cancer","Leo","Virgo",
                     "Libra","Scorpio","Sagittarius","Capricorn","Aquarius","Pisces"]
        return signs[Int(ascendant / 30) % 12]
    }
    
    var midheavenSign: String {
        let signs = ["Aries","Taurus","Gemini","Cancer","Leo","Virgo",
                     "Libra","Scorpio","Sagittarius","Capricorn","Aquarius","Pisces"]
        return signs[Int(midheaven / 30) % 12]
    }
}
