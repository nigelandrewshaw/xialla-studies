import Foundation

#if canImport(ResearchKit)
import ResearchKit

/// Builds ResearchKit ordered tasks for consent and surveys.
/// IIEF-5 uses horizontal scale sliders (1–5) with **defaultValue 3** and official wording.
enum ResearchKitTaskFactory {
    static let isAvailable = true

    /// Retained so the consent presenter can export a PDF after the task completes.
    static var lastConsentDocument: ORKConsentDocument?

    // MARK: - Consent

    static func makeConsentTask() -> ORKOrderedTask {
        let document = ORKConsentDocument()
        document.title = "Xialla Observational Study"
        document.sections = [
            section(
                .overview,
                title: "Purpose",
                summary: "This is a prospective observational study of Xialla use among men.",
                content: """
                You are being invited to take part in an observational study of Xialla. \
                The study looks at how erectile function (IIEF-5) and related experiences \
                change over about four weeks of real-world use. This is not a treatment program, \
                drug trial, or diagnostic service. Participation is voluntary.
                """
            ),
            section(
                .custom,
                title: "Procedures",
                summary: "You will complete baseline questionnaires before first use, then a week‑4 follow-up.",
                content: """
                If you join, you will: (1) confirm eligibility, (2) complete baseline surveys \
                including the IIEF-5 and brief history, usability, comfort, satisfaction, and \
                adverse-event questions, (3) use Xialla as you normally would, and (4) complete \
                a week‑4 follow-up in the app. Optional local reminders help you remember the follow-up. \
                Records are tagged with study_code and site_code for the coordinating site.
                """
            ),
            section(
                .dataGathering,
                title: "Data use",
                summary: "Survey answers and consent metadata are stored for the study.",
                content: """
                We collect questionnaire responses, consent status, timestamps, and study/site codes. \
                Data stay on your device until a secure sync to the study cloud database is available. \
                De-identified aggregate results may be used for research reporting. We do not sell your data.
                """
            ),
            section(
                .privacy,
                title: "Privacy and risks",
                summary: "Sexual-health answers are sensitive, and a residual privacy risk remains.",
                content: """
                Sexual health information is sensitive. We apply technical safeguards appropriate for a \
                HIPAA-oriented study environment when syncing. Risks include discomfort answering personal \
                questions and residual privacy risk if a device is lost or compromised. Benefits include \
                contributing to understanding of Xialla use; there is no guarantee of personal medical benefit.
                """
            ),
            section(
                .withdrawing,
                title: "Withdrawal",
                summary: "You may withdraw at any time from Settings.",
                content: """
                You can stop at any time without penalty by using Withdraw in Settings. \
                Data already collected may remain in the study dataset as permitted by the protocol \
                and ethics approval. Contact the site team with questions before or after signing.
                """
            ),
            section(
                .custom,
                title: "Contact",
                summary: "The first site investigator is Dr. Jeffrey Campbell at St. Joseph’s London.",
                content: """
                If you have questions about the study, contact your site investigator. \
                The site code and study code appear in Settings. Replace this stub with IRB-approved \
                contact language before enrollment.
                """
            )
        ]

        let signature = ORKConsentSignature(
            forPersonWithTitle: "Participant",
            dateFormatString: nil,
            identifier: "participant.signature"
        )
        document.addSignature(signature)
        lastConsentDocument = document

        // ResearchKit 3+: `ORKVisualConsentStep` was removed. Prefer instruction pages
        // derived from the consent document, then comprehension + signature review.
        var steps: [ORKStep] = document.instructionSteps.map { $0 as ORKStep }
        if steps.isEmpty {
            let overview = ORKInstructionStep(identifier: "consent.overview")
            overview.title = document.title ?? "Informed consent"
            overview.detailText = """
            Please review the study information, answer the comprehension check, \
            and sign to join this observational study of Xialla use.
            """
            steps = [overview]
        }

        let comprehension = ORKFormStep(
            identifier: "consent.comprehension",
            title: "Comprehension check",
            text: "Please confirm that you understand what kind of study this is before you sign."
        )
        comprehension.formItems = [
            ORKFormItem(
                identifier: "consent.comprehension.choice",
                text: "Which of the following best describes this study?",
                answerFormat: ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
                    ORKTextChoice(
                        text: "An observational study of Xialla use (not a treatment program)",
                        value: "observational" as NSString
                    ),
                    ORKTextChoice(text: "A clinical trial of a new drug", value: "drug" as NSString),
                    ORKTextChoice(
                        text: "A diagnostic testing service for erectile dysfunction",
                        value: "dx" as NSString
                    )
                ])
            )
        ]
        steps.append(comprehension)

        // Pass the document signature so name + finger-scrawl are collected.
        let review = ORKConsentReviewStep(identifier: "consent.review", signature: signature, in: document)
        review.reasonForConsent = "I agree to join this observational study of Xialla use."
        steps.append(review)

        return ORKOrderedTask(identifier: "xialla.consent", steps: steps)
    }

    private static func section(
        _ type: ORKConsentSectionType,
        title: String,
        summary: String,
        content: String
    ) -> ORKConsentSection {
        let section = ORKConsentSection(type: type)
        section.title = title
        section.summary = summary
        section.content = content
        return section
    }

    // MARK: - Surveys

    static func makeSurveyTask(timepoint: SurveyTimepoint) -> ORKOrderedTask {
        var steps: [ORKStep] = []

        let intro = ORKInstructionStep(identifier: "survey.\(timepoint.rawValue).intro")
        intro.title = timepoint.displayName
        intro.detailText = timepoint == .baseline
            ? "Please complete these questionnaires before your first study use of Xialla when possible. The IIEF-5 items use a 1–5 slider that starts at 3."
            : "This is your week‑4 follow-up. The IIEF-5 items use a 1–5 slider that starts at 3."
        steps.append(intro)

        for instrument in timepoint.instruments {
            steps.append(contentsOf: steps(for: instrument, timepoint: timepoint))
        }

        let done = ORKCompletionStep(identifier: "survey.\(timepoint.rawValue).done")
        done.title = "Responses saved"
        done.text = "Your responses stay on this device until the study API syncs. Your IIEF-5 total is scored locally on a scale from 5 to 25."
        steps.append(done)

        return ORKOrderedTask(identifier: "xialla.survey.\(timepoint.rawValue)", steps: steps)
    }

    /// One instrument only — used when the participant taps a list row.
    static func makeInstrumentTask(
        timepoint: SurveyTimepoint,
        instrument: InstrumentCode
    ) -> ORKOrderedTask {
        var steps: [ORKStep] = []
        let intro = ORKInstructionStep(identifier: "survey.\(timepoint.rawValue).\(instrument.rawValue).intro")
        intro.title = instrument.displayName
        intro.detailText = "You can leave and open any other questionnaire from the list at any time."
        steps.append(intro)
        steps.append(contentsOf: steps(for: instrument, timepoint: timepoint))
        let done = ORKCompletionStep(identifier: "survey.\(timepoint.rawValue).\(instrument.rawValue).done")
        done.title = "Saved"
        done.text = "This questionnaire is saved on this device. Return to the list for any remaining items."
        steps.append(done)
        return ORKOrderedTask(
            identifier: "xialla.survey.\(timepoint.rawValue).\(instrument.rawValue)",
            steps: steps
        )
    }

    private static func steps(for instrument: InstrumentCode, timepoint: SurveyTimepoint) -> [ORKStep] {
        switch instrument {
        case .iief5:
            return [iief5Form(timepoint: timepoint)]
        case .baselineHistory:
            return [baselineHistoryForm()]
        case .usability:
            return [likertForm(
                id: "\(timepoint.rawValue).usability",
                title: "Usability",
                prompt: "Thinking about your experience so far, how easy was Xialla to use?",
                low: "Very difficult",
                high: "Very easy"
            )]
        case .comfort:
            return [likertForm(
                id: "\(timepoint.rawValue).comfort",
                title: "Comfort",
                prompt: "How comfortable was Xialla to wear during use?",
                low: "Very uncomfortable",
                high: "Very comfortable"
            )]
        case .satisfaction:
            return [likertForm(
                id: "\(timepoint.rawValue).satisfaction",
                title: "Satisfaction",
                prompt: "Overall, how satisfied are you with Xialla?",
                low: "Very dissatisfied",
                high: "Very satisfied"
            )]
        case .adverseEvents:
            return [adverseEventsForm(timepoint: timepoint)]
        case .freeText:
            return [freeTextForm(timepoint: timepoint)]
        }
    }

    /// IIEF-5: five horizontal scale sliders, range 1–5, **default 3**, official item wording.
    private static func iief5Form(timepoint: SurveyTimepoint) -> ORKFormStep {
        let step = ORKFormStep(
            identifier: "iief5.\(timepoint.rawValue)",
            title: "IIEF-5",
            text: """
            \(IIEF5Scoring.recallPeriodInstruction) \
            Please rate each item from 1 to 5 using the slider. Each slider starts at 3.
            """
        )
        var items: [ORKFormItem] = []
        for (index, item) in IIEF5Scoring.items.enumerated() {
            let q = index + 1
            let format = ORKScaleAnswerFormat(
                maximumValue: 5,
                minimumValue: 1,
                defaultValue: 3,
                step: 1,
                vertical: false,
                maximumValueDescription: item.highLabel,
                minimumValueDescription: item.lowLabel
            )
            let formItem = ORKFormItem(
                identifier: "iief5.q\(q)",
                text: "\(q). \(item.prompt)",
                answerFormat: format
            )
            items.append(formItem)
        }
        step.formItems = items
        return step
    }

    private static func baselineHistoryForm() -> ORKFormStep {
        let step = ORKFormStep(
            identifier: "baseline.history",
            title: "Baseline history",
            text: "Please answer these brief history questions before your first study use of Xialla."
        )
        step.formItems = [
            ORKFormItem(
                identifier: "baseline.history.prior_ed_tx",
                text: "Have you used other treatments for erectile dysfunction before starting this study?",
                answerFormat: ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
                    ORKTextChoice(text: "Yes", value: "yes" as NSString),
                    ORKTextChoice(text: "No", value: "no" as NSString),
                    ORKTextChoice(text: "Prefer not to say", value: "na" as NSString)
                ])
            ),
            ORKFormItem(
                identifier: "baseline.history.notes",
                text: "Is there anything else you would like the study team to know about your history before first use of Xialla?",
                answerFormat: ORKTextAnswerFormat(maximumLength: 400)
            )
        ]
        return step
    }

    private static func likertForm(
        id: String,
        title: String,
        prompt: String,
        low: String,
        high: String
    ) -> ORKFormStep {
        let step = ORKFormStep(identifier: id, title: title, text: prompt)
        let format = ORKScaleAnswerFormat(
            maximumValue: 5,
            minimumValue: 1,
            defaultValue: 3,
            step: 1,
            vertical: false,
            maximumValueDescription: high,
            minimumValueDescription: low
        )
        step.formItems = [
            ORKFormItem(identifier: "\(id).score", text: prompt, answerFormat: format)
        ]
        return step
    }

    private static func adverseEventsForm(timepoint: SurveyTimepoint) -> ORKFormStep {
        let id = "\(timepoint.rawValue).adverseEvents"
        let step = ORKFormStep(
            identifier: id,
            title: "Adverse events",
            text: "Please report any problems that may be related to Xialla use since the last questionnaire."
        )
        step.formItems = [
            ORKFormItem(
                identifier: "\(id).any",
                text: "Did you experience any adverse events or problems that you think may be related to using Xialla?",
                answerFormat: ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
                    ORKTextChoice(text: "No", value: "no" as NSString),
                    ORKTextChoice(text: "Yes", value: "yes" as NSString)
                ])
            ),
            ORKFormItem(
                identifier: "\(id).detail",
                text: "If you answered yes, please briefly describe what happened.",
                answerFormat: ORKTextAnswerFormat(maximumLength: 500)
            )
        ]
        return step
    }

    private static func freeTextForm(timepoint: SurveyTimepoint) -> ORKFormStep {
        let id = "\(timepoint.rawValue).freeText"
        let step = ORKFormStep(
            identifier: id,
            title: "Additional comments",
            text: "You may share any additional comments for the study team. This step is optional."
        )
        step.formItems = [
            ORKFormItem(
                identifier: "\(id).note",
                text: "Please share any additional comments for the study team.",
                answerFormat: ORKTextAnswerFormat(maximumLength: 800)
            )
        ]
        return step
    }
}

#else

/// Present when ResearchKit is not linked — branded SwiftUI surveys still run.
enum ResearchKitTaskFactory {
    static let isAvailable = false
}

#endif
