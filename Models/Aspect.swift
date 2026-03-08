import Foundation

// The geometric angles between planets that matter in astrology
enum AspectType: String, CaseIterable, Codable {
    case conjunction = "Conjunction"
    case opposition  = "Opposition"
    case square      = "Square"
    case trine       = "Trine"
    case sextile     = "Sextile"
    
    // The exact angle this aspect represents
    var angle: Double {
        switch self {
        case .conjunction: return 0
        case .opposition:  return 180
        case .square:      return 90
        case .trine:       return 120
        case .sextile:     return 60
        }
    }
    
    // How important is this aspect for scoring?
    var importance: Int {
        switch self {
        case .conjunction: return 5
        case .opposition:  return 4
        case .square:      return 4
        case .trine:       return 3
        case .sextile:     return 2
        }
    }
    
    // What is the general "tone" of this aspect?
    var tone: String {
        switch self {
        case .conjunction: return "a merging and intensifying of energies"
        case .opposition:  return "a tension between opposing forces"
        case .square:      return "friction that demands action and change"
        case .trine:       return "harmony and natural flow"
        case .sextile:     return "a gentle opportunity or helpful opening"
        }
    }
    
    // Is this aspect challenging or supportive?
    var nature: AspectNature {
        switch self {
        case .conjunction: return .neutral
        case .opposition:  return .challenging
        case .square:      return .challenging
        case .trine:       return .harmonious
        case .sextile:     return .harmonious
        }
    }
    
    // A short glyph symbol
    var symbol: String {
        switch self {
        case .conjunction: return "☌"
        case .opposition:  return "☍"
        case .square:      return "□"
        case .trine:       return "△"
        case .sextile:     return "⚹"
        }
    }
}

enum AspectNature: String, Codable {
    case harmonious  = "Harmonious"
    case challenging = "Challenging"
    case neutral     = "Neutral"
    
    var color: String {
        switch self {
        case .harmonious:  return "blue"
        case .challenging: return "red"
        case .neutral:     return "purple"
        }
    }
}

// The maximum degrees of error we allow when detecting an aspect
let ASPECT_ORB: Double = 3.0
