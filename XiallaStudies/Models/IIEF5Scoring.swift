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
}
