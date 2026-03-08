import Foundation

// MARK: - Protocol (the "contract" Swiss Ephemeris would fulfill later)
// This protocol defines what ANY astronomy engine must be able to do.
// If we swap in Swiss Ephemeris later, it just needs to conform to this.
protocol AstronomyEngineProtocol {
    func calculatePlanets(for date: Date, latitude: Double, longitude: Double) -> [Planet]
    func calculateHouses(for date: Date, latitude: Double, longitude: Double) -> (ascendant: Double, midheaven: Double, houses: [Double])
}

// MARK: - Main Engine
struct AstronomyEngine: AstronomyEngineProtocol {
    
    // MARK: - Public Interface
    
    func calculatePlanets(for date: Date, latitude: Double, longitude: Double) -> [Planet] {
        let jd = julianDay(from: date)
        return PlanetName.allCases.map { planetName in
            let degree = calculatePlanetDegree(planet: planetName, julianDay: jd)
            let retrograde = isRetrograde(planet: planetName, julianDay: jd)
            return Planet(name: planetName, degree: degree, isRetrograde: retrograde)
        }
    }
    
    func calculateHouses(for date: Date, latitude: Double, longitude: Double) -> (ascendant: Double, midheaven: Double, houses: [Double]) {
        let jd = julianDay(from: date)
        return calculatePlacidusHouses(julianDay: jd, latitude: latitude, longitude: longitude)
    }
    
    // MARK: - Julian Day
    // Julian Day is a continuous count of days since Jan 1, 4713 BC.
    // Astronomers use it to simplify date calculations.
    func julianDay(from date: Date) -> Double {
        let jd2000 = 2451545.0  // Julian Day for Jan 1, 2000 at noon
        let secondsSince2000 = date.timeIntervalSince(
            Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1, hour: 12))!
        )
        return jd2000 + secondsSince2000 / 86400.0
    }
    
    // MARK: - Planet Degree Calculation
    // These are simplified mean longitude formulas based on real orbital elements.
    // They are accurate to within ~1–2 degrees for modern dates.
    private func calculatePlanetDegree(planet: PlanetName, julianDay jd: Double) -> Double {
        // T = centuries since J2000.0
        let T = (jd - 2451545.0) / 36525.0
        
        var degree: Double
        
        switch planet {
        case .sun:
            // Solar longitude (apparent)
            let L0 = 280.46646 + 36000.76983 * T
            let M  = (357.52911 + 35999.05029 * T).toRadians()
            let C  = (1.914602 - 0.004817 * T) * sin(M)
                   + 0.019993 * sin(2 * M)
            degree = L0 + C
            
        case .moon:
            // Moon's mean longitude
            let L = 218.3164477 + 481267.88123421 * T
            let M = (134.9633964 + 477198.8675055 * T).toRadians()
            let F = (93.2720950 + 483202.0175233 * T).toRadians()
            degree = L + 6.289 * sin(M) - 1.274 * sin(2 * F - M) + 0.658 * sin(2 * F)
            
        case .mercury:
            degree = 252.2507 + 149474.0 * T + 0.3 * sin((174.8 + 149474.0 * T).toRadians())
            
        case .venus:
            degree = 181.9798 + 58519.213 * T + 0.8 * sin((50.4 + 58519.2 * T).toRadians())
            
        case .mars:
            degree = 355.4330 + 19141.696 * T + 1.1 * sin((19.4 + 19141.7 * T).toRadians())
            
        case .jupiter:
            degree = 34.3515 + 3036.301 * T + 0.5 * sin((20.9 + 3036.3 * T).toRadians())
            
        case .saturn:
            degree = 50.0774 + 1223.011 * T + 0.4 * sin((57.8 + 1223.0 * T).toRadians())
            
        case .uranus:
            degree = 314.0550 + 429.867 * T + 0.3 * sin((142.5 + 429.9 * T).toRadians())
            
        case .neptune:
            degree = 304.3487 + 219.885 * T + 0.2 * sin((77.3 + 219.9 * T).toRadians())
            
        case .pluto:
            degree = 238.9508 + 145.181 * T + 0.1 * sin((357.5 + 145.2 * T).toRadians())
        }
        
        return normalizeAngle(degree)
    }
    
    // MARK: - Retrograde Detection
    // A planet is retrograde when it appears to move backward.
    // We detect this by comparing position slightly forward vs backward in time.
    private func isRetrograde(planet: PlanetName, julianDay jd: Double) -> Bool {
        guard planet != .sun && planet != .moon else { return false }
        let before = calculatePlanetDegree(planet: planet, julianDay: jd - 0.5)
        let after  = calculatePlanetDegree(planet: planet, julianDay: jd + 0.5)
        
        // Account for 0°/360° wraparound
        var diff = after - before
        if diff > 180  { diff -= 360 }
        if diff < -180 { diff += 360 }
        
        return diff < 0
    }
    
    // MARK: - Placidus House System
    // The Placidus system divides the sky into 12 houses based on
    // the time it takes degrees to rise from horizon to midheaven.
    private func calculatePlacidusHouses(julianDay jd: Double, latitude: Double, longitude: Double) -> (ascendant: Double, midheaven: Double, houses: [Double]) {
        
        // Local Sidereal Time
        let lst = localSiderealTime(julianDay: jd, longitude: longitude)
        
        // Midheaven (MC) — the degree of the zodiac directly overhead
        let mc = normalizeAngle(atan2(
            tan(lst.toRadians()),
            cos((23.4393 - 0.0130042 * (jd - 2451545.0) / 36525.0).toRadians())
        ).toDegrees())
        
        // Obliquity of the ecliptic (Earth's axial tilt)
        let T = (jd - 2451545.0) / 36525.0
        let eps = (23.4393 - 0.0130042 * T).toRadians()
        let latRad = latitude.toRadians()
        
        // Ascendant — the degree rising on the eastern horizon
        let ramc = lst.toRadians()
        let ascendant = normalizeAngle(
            atan2(cos(ramc), -(sin(ramc) * cos(eps) + tan(latRad) * sin(eps)))
            .toDegrees()
        )
        
        // Placidus intermediate house cusps (houses 2, 3, 11, 12)
        // Remaining cusps are derived by adding 180°
        var houses = Array(repeating: 0.0, count: 12)
        houses[0]  = ascendant          // 1st house = Ascendant
        houses[9]  = mc                 // 10th house = Midheaven
        houses[6]  = normalizeAngle(ascendant + 180) // 7th = opposite ASC
        houses[3]  = normalizeAngle(mc + 180)         // 4th = opposite MC
        
        // Interpolate houses 11, 12, 2, 3 using Placidus formula
        houses[10] = placidusIntermediate(mc: mc, ascendant: ascendant, latitude: latRad, eps: eps, fraction: 1.0/3.0)
        houses[11] = placidusIntermediate(mc: mc, ascendant: ascendant, latitude: latRad, eps: eps, fraction: 2.0/3.0)
        houses[1]  = normalizeAngle(houses[7] + 180)  // placeholder
        houses[2]  = normalizeAngle(houses[8] + 180)  // placeholder
        houses[4]  = placidusIntermediate(mc: mc, ascendant: ascendant, latitude: latRad, eps: eps, fraction: 1.0/3.0 + 0.5)
        houses[5]  = placidusIntermediate(mc: mc, ascendant: ascendant, latitude: latRad, eps: eps, fraction: 2.0/3.0 + 0.5)
        houses[7]  = normalizeAngle(houses[10] + 180)
        houses[8]  = normalizeAngle(houses[11] + 180)
        houses[1]  = normalizeAngle(houses[4]  + 180)
        houses[2]  = normalizeAngle(houses[5]  + 180)
        
        return (ascendant: ascendant, midheaven: mc, houses: houses)
    }
    
    private func placidusIntermediate(mc: Double, ascendant: Double, latitude: Double, eps: Double, fraction: Double) -> Double {
        let span = normalizeAngle(ascendant - mc)
        return normalizeAngle(mc + span * fraction)
    }
    
    // MARK: - Local Sidereal Time
    // Sidereal time tracks the rotation of the Earth relative to the stars
    private func localSiderealTime(julianDay jd: Double, longitude: Double) -> Double {
        let T = (jd - 2451545.0) / 36525.0
        var gst = 280.46061837
                + 360.98564736629 * (jd - 2451545.0)
                + 0.000387933 * T * T
        gst = normalizeAngle(gst)
        return normalizeAngle(gst + longitude)
    }
    
    // MARK: - Helpers
    
    // Keeps any angle within 0–360°
    func normalizeAngle(_ angle: Double) -> Double {
        var result = angle.truncatingRemainder(dividingBy: 360)
        if result < 0 { result += 360 }
        return result
    }
}

// MARK: - Degree/Radian Extensions
// Swift's trig functions use radians. These helpers let us work in degrees.
extension Double {
    func toRadians() -> Double { self * .pi / 180 }
    func toDegrees() -> Double { self * 180 / .pi }
}
