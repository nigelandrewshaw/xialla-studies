import Foundation

/// IIEF-5 total score helpers (5–25) and official instrument item wording
/// (Rosen et al., Int J Impot Res 1999; license cleared for this study).
enum IIEF5Scoring {
    enum Band: String, Codable, Equatable {
        case severe
        case moderate
        case mildToModerate
        case mild
        case none
        case invalid
    }

    /// One official IIEF-5 item with endpoint labels for the 1–5 scale.
    struct Item: Equatable {
        let prompt: String
        let lowLabel: String
        let highLabel: String
    }

    /// Official recall framing for the IIEF-5 questionnaire.
    static let recallPeriodInstruction = "Over the past six months:"

    /// Official IIEF-5 items (Rosen et al. 1999). Sliders remain 1–5 with default 3.
    static let items: [Item] = [
        Item(
            prompt: "How do you rate your confidence that you could get and keep an erection?",
            lowLabel: "Very low",
            highLabel: "Very high"
        ),
        Item(
            prompt: "When you had erections with sexual stimulation, how often were your erections hard enough for penetration?",
            lowLabel: "Almost never/never",
            highLabel: "Almost always/always"
        ),
        Item(
            prompt: "During sexual intercourse, how often were you able to maintain your erection after you had penetrated (entered) your partner?",
            lowLabel: "Almost never/never",
            highLabel: "Almost always/always"
        ),
        Item(
            prompt: "During sexual intercourse, how difficult was it to maintain your erection to completion of intercourse?",
            lowLabel: "Extremely difficult",
            highLabel: "Not difficult"
        ),
        Item(
            prompt: "When you attempted sexual intercourse, how often was it satisfactory for you?",
            lowLabel: "Almost never/never",
            highLabel: "Almost always/always"
        )
    ]

    /// Convenience: official prompts only, in instrument order.
    static var itemPrompts: [String] { items.map(\.prompt) }

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
