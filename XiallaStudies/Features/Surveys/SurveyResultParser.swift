import Foundation

struct SurveyTaskOutcome: Equatable {
    var administrations: [SurveyAdministration]
    var iief5Total: Int?
    var iief5Band: IIEF5Scoring.Band?
}

/// Builds survey outcomes from the branded SwiftUI instrument sheets.
enum SurveyResultParser {
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
