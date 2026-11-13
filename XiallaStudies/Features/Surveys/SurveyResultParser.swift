import Foundation

#if canImport(ResearchKit)
import ResearchKit
#endif

struct SurveyTaskOutcome: Equatable {
    var administrations: [SurveyAdministration]
    var iief5Total: Int?
    var iief5Band: IIEF5Scoring.Band?
}

enum SurveyResultParser {
    #if canImport(ResearchKit)
    static func parse(taskResult: ORKTaskResult, timepoint: SurveyTimepoint) -> SurveyTaskOutcome {
        var administrations: [SurveyAdministration] = []
        let enrollmentId = UUID()

        let iiefAnswers = iief5Answers(from: taskResult, timepoint: timepoint)
        let total = IIEF5Scoring.total(answers: iiefAnswers)
        let band = total.map { IIEF5Scoring.band(for: $0) }

        let iiefResponses: [SurveyResponseItem] = iiefAnswers.enumerated().map { index, value in
            SurveyResponseItem(
                id: UUID(),
                itemCode: "iief5.q\(index + 1)",
                value: String(value),
                answeredAt: Date()
            )
        }
        administrations.append(
            SurveyAdministration(
                id: UUID(),
                enrollmentId: enrollmentId,
                instrument: .iief5,
                timepoint: timepoint,
                status: .completed,
                startedAt: Date(),
                completedAt: Date(),
                responses: iiefResponses,
                scoreTotal: total,
                scoreBand: band.map { IIEF5Scoring.displayName(for: $0) },
                meta: .makeNow()
            )
        )

        let otherCodes: [InstrumentCode]
        if timepoint == .baseline {
            otherCodes = [.baselineHistory, .usability, .comfort, .satisfaction, .adverseEvents, .freeText]
        } else {
            otherCodes = [.usability, .comfort, .satisfaction, .adverseEvents, .freeText]
        }

        for code in otherCodes {
            let stepId: String
            switch code {
            case .baselineHistory: stepId = "baseline.history"
            default: stepId = "\(timepoint.rawValue).\(code.rawValue)"
            }
            let responses = formResponses(from: taskResult, stepIdentifier: stepId)
            administrations.append(
                SurveyAdministration(
                    id: UUID(),
                    enrollmentId: enrollmentId,
                    instrument: code,
                    timepoint: timepoint,
                    status: .completed,
                    startedAt: Date(),
                    completedAt: Date(),
                    responses: responses,
                    scoreTotal: nil,
                    scoreBand: nil,
                    meta: .makeNow()
                )
            )
        }

        return SurveyTaskOutcome(
            administrations: administrations,
            iief5Total: total,
            iief5Band: band
        )
    }

    private static func iief5Answers(from taskResult: ORKTaskResult, timepoint: SurveyTimepoint) -> [Int] {
        guard let step = taskResult.stepResult(forStepIdentifier: "iief5.\(timepoint.rawValue)") else {
            return Array(repeating: 3, count: 5)
        }
        var answers: [Int] = []
        for q in 1...5 {
            let id = "iief5.q\(q)"
            if let scale = step.result(forIdentifier: id) as? ORKScaleQuestionResult,
               let value = scale.scaleAnswer?.intValue {
                answers.append(value)
            } else {
                answers.append(3)
            }
        }
        return answers
    }

    private static func formResponses(from taskResult: ORKTaskResult, stepIdentifier: String) -> [SurveyResponseItem] {
        guard let step = taskResult.stepResult(forStepIdentifier: stepIdentifier) else {
            return [
                SurveyResponseItem(id: UUID(), itemCode: "\(stepIdentifier).empty", value: "", answeredAt: Date())
            ]
        }
        var items: [SurveyResponseItem] = []
        for result in step.results ?? [] {
            let value: String
            if let scale = result as? ORKScaleQuestionResult {
                value = scale.scaleAnswer?.stringValue ?? ""
            } else if let choice = result as? ORKChoiceQuestionResult {
                value = (choice.choiceAnswers?.first as? String) ?? String(describing: choice.choiceAnswers?.first ?? "")
            } else if let text = result as? ORKTextQuestionResult {
                value = text.textAnswer ?? ""
            } else if let bool = result as? ORKBooleanQuestionResult {
                value = bool.booleanAnswer?.boolValue == true ? "true" : "false"
            } else {
                value = result.identifier
            }
            items.append(
                SurveyResponseItem(
                    id: UUID(),
                    itemCode: result.identifier,
                    value: value,
                    answeredAt: Date()
                )
            )
        }
        return items
    }
    #endif

    static func fromBrandedIIEF5(
        timepoint: SurveyTimepoint,
        answers: [Int],
        companionNotes: [InstrumentCode: String] = [:]
    ) -> SurveyTaskOutcome {
        .emptyDefaults(timepoint: timepoint, answers: answers, companionNotes: companionNotes)
    }
}

extension SurveyTaskOutcome {
    static func emptyDefaults(
        timepoint: SurveyTimepoint,
        answers: [Int],
        companionNotes: [InstrumentCode: String] = [:]
    ) -> SurveyTaskOutcome {
        let total = IIEF5Scoring.total(answers: answers)
        let band = total.map { IIEF5Scoring.band(for: $0) }
        var admins: [SurveyAdministration] = [
            SurveyAdministration(
                id: UUID(),
                enrollmentId: UUID(),
                instrument: .iief5,
                timepoint: timepoint,
                status: .completed,
                startedAt: Date(),
                completedAt: Date(),
                responses: answers.enumerated().map { i, v in
                    SurveyResponseItem(
                        id: UUID(),
                        itemCode: "iief5.q\(i + 1)",
                        value: String(v),
                        answeredAt: Date()
                    )
                },
                scoreTotal: total,
                scoreBand: band.map { IIEF5Scoring.displayName(for: $0) },
                meta: .makeNow()
            )
        ]
        let others: [InstrumentCode] = timepoint == .baseline
            ? [.baselineHistory, .usability, .comfort, .satisfaction, .adverseEvents, .freeText]
            : [.usability, .comfort, .satisfaction, .adverseEvents, .freeText]
        for code in others {
            admins.append(
                SurveyAdministration(
                    id: UUID(),
                    enrollmentId: UUID(),
                    instrument: code,
                    timepoint: timepoint,
                    status: .completed,
                    startedAt: Date(),
                    completedAt: Date(),
                    responses: [
                        SurveyResponseItem(
                            id: UUID(),
                            itemCode: "\(code.rawValue).note",
                            value: companionNotes[code] ?? "completed",
                            answeredAt: Date()
                        )
                    ],
                    scoreTotal: nil,
                    scoreBand: nil,
                    meta: .makeNow()
                )
            )
        }
        return SurveyTaskOutcome(administrations: admins, iief5Total: total, iief5Band: band)
    }
}
