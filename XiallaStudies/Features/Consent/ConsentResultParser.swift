import Foundation

#if canImport(ResearchKit)
import ResearchKit

enum ConsentResultParser {
    static func signatureReference(from taskResult: ORKTaskResult) -> String? {
        guard let review = taskResult.stepResult(forStepIdentifier: "consent.review") else {
            return "rk-consent-completed"
        }
        for result in review.results ?? [] {
            if let signature = result as? ORKConsentSignatureResult {
                let name = [signature.signature?.givenName, signature.signature?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                if !name.isEmpty {
                    return "rk-signature:\(name)"
                }
            }
        }
        return "rk-consent-completed"
    }

    static func comprehensionPassed(from taskResult: ORKTaskResult) -> Bool {
        guard
            let step = taskResult.stepResult(forStepIdentifier: "consent.comprehension"),
            let choice = step.results?.first as? ORKChoiceQuestionResult,
            let value = choice.choiceAnswers?.first as? String
        else {
            return false
        }
        return value == "observational"
    }
}

#else

enum ConsentResultParser {
    static func signatureReference(from taskResult: Any) -> String? { nil }
    static func comprehensionPassed(from taskResult: Any) -> Bool { true }
}

#endif
