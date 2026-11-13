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
        var iiefTotal: Int?
        var iiefBand: IIEF5Scoring.Band?

        for instrument in timepoint.instruments {
            let piece = parseInstrument(
                taskResult: taskResult,
                timepoint: timepoint,
                instrument: instrument
            )
            administrations.append(contentsOf: piece.administrations)
            if instrument == .iief5 {
                iiefTotal = piece.iief5Total
                iiefBand = piece.iief5Band
            }
        }

        return SurveyTaskOutcome(
            administrations: administrations,
            iief5Total: iiefTotal,
            iief5Band: iiefBand
        )
    }

    static func parseInstrument(
        taskResult: ORKTaskResult,
        timepoint: SurveyTimepoint,
        instrument: InstrumentCode
    ) -> SurveyTaskOutcome {
        let enrollmentId = UUID()
        switch instrument {
        case .iief5:
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
            let admin = SurveyAdministration(
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
            return SurveyTaskOutcome(administrations: [admin], iief5Total: total, iief5Band: band)
        case .baselineHistory, .usability, .comfort, .satisfaction, .adverseEvents, .freeText:
            let stepId: String
            switch instrument {
            case .baselineHistory: stepId = "baseline.history"
            default: stepId = "\(timepoint.rawValue).\(instrument.rawValue)"
            }
            let responses = formResponses(from: taskResult, stepIdentifier: stepId)
            let admin = SurveyAdministration(
                id: UUID(),
                enrollmentId: enrollmentId,
                instrument: instrument,
                timepoint: timepoint,
                status: .completed,
                startedAt: Date(),
                completedAt: Date(),
                responses: responses,
                scoreTotal: nil,
                scoreBand: nil,
                meta: .makeNow()
            )
            return SurveyTaskOutcome(administrations: [admin], iief5Total: nil, iief5Band: nil)
        }
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
                // choiceAnswers are NSObject & NSCopying & NSSecureCoding (often NSString), not String.
                value = stringifyORKAnswer(choice.choiceAnswers?.first)
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

    /// Bridges ORK choice / scale boxed values into plain strings for local persistence.
    private static func stringifyORKAnswer(_ answer: (any NSCopying & NSSecureCoding & NSObjectProtocol)?) -> String {
        if let string = answer as? String {
            return string
        }
        if let nsString = answer as? NSString {
            return nsString as String
        }
        if let number = answer as? NSNumber {
            return number.stringValue
        }
        if let answer {
            return String(describing: answer)
        }
        return ""
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
        for code in timepoint.instruments where code != .iief5 {
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

    /// One IIEF-5 administration from the per-row survey sheet.
    static func singleIIEF5(timepoint: SurveyTimepoint, answers: [Int]) -> SurveyTaskOutcome {
        let total = IIEF5Scoring.total(answers: answers)
        let band = total.map { IIEF5Scoring.band(for: $0) }
        let admin = SurveyAdministration(
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
        return SurveyTaskOutcome(administrations: [admin], iief5Total: total, iief5Band: band)
    }

    /// One non–IIEF-5 administration from the per-row survey sheet.
    static func singleNote(
        instrument: InstrumentCode,
        timepoint: SurveyTimepoint,
        value: String
    ) -> SurveyTaskOutcome {
        let admin = SurveyAdministration(
            id: UUID(),
            enrollmentId: UUID(),
            instrument: instrument,
            timepoint: timepoint,
            status: .completed,
            startedAt: Date(),
            completedAt: Date(),
            responses: [
                SurveyResponseItem(
                    id: UUID(),
                    itemCode: "\(instrument.rawValue).note",
                    value: value,
                    answeredAt: Date()
                )
            ],
            scoreTotal: nil,
            scoreBand: nil,
            meta: .makeNow()
        )
        return SurveyTaskOutcome(administrations: [admin], iief5Total: nil, iief5Band: nil)
    }
}
