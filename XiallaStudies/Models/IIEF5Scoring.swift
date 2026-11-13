import Foundation

/// IIEF-5 total score helpers (5–25). Item wording is separate and must be licensing-cleared.
enum IIEF5Scoring {
    enum Band: String, Codable, Equatable {
        case severe
        case moderate
        case mildToModerate
        case mild
        case none
        case invalid
    }

    /// Paraphrased placeholders — replace with licensed IIEF-5 item text before shipping.
    static let placeholderPrompts: [String] = [
        "Confidence that you could get and keep an erection (1 = very low, 5 = very high)",
        "Erections hard enough for penetration when sexually stimulated (1 = almost never, 5 = almost always)",
        "Ability to maintain erection after penetration (1 = almost never, 5 = almost always)",
        "Ability to maintain erection to completion of intercourse (1 = extremely difficult, 5 = not difficult)",
        "Satisfaction with sexual intercourse (1 = almost never, 5 = almost always)"
    ]

    static func total(answers: [Int]) -> Int? {
        guard answers.count == 5, answers.allSatisfy({ (1...5).contains($0) }) else {
            return nil
        }
        return answers.reduce(0, +)
    }

    static func band(for total: Int) -> Band {
        switch total {
        case 5...7: return .severe
        case 8...11: return .moderate
        case 12...16: return .mildToModerate
        case 17...21: return .mild
        case 22...25: return .none
        default: return .invalid
        }
    }

    static func displayName(for band: Band) -> String {
        switch band {
        case .severe: return "severe"
        case .moderate: return "moderate"
        case .mildToModerate: return "mild-to-moderate"
        case .mild: return "mild"
        case .none: return "no ED"
        case .invalid: return "invalid"
        }
    }
}
