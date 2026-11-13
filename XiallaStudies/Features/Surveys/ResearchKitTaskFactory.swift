import Foundation

#if canImport(ResearchKit)
import ResearchKit
#else
/// Present when ResearchKit is not linked — branded SwiftUI surveys still run.
enum ResearchKitTaskFactory {
    static let isAvailable = false
}
#endif

#if canImport(ResearchKit)

/// Builds ResearchKit ordered tasks for consent and surveys.
/// IIEF-5 uses horizontal scale sliders (1–5) with **defaultValue 3**.
enum ResearchKitTaskFactory {
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
                summary: "Baseline questionnaires before first use, then a week‑4 follow-up.",
                content: """
                If you join, you will: (1) confirm eligibility, (2) complete baseline surveys \
                including IIEF-5 and brief history / usability / comfort / satisfaction / \
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
                title: "Privacy & risks",
                summary: "Sexual-health answers are sensitive; residual privacy risk remains.",
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
                summary: "First site: Dr. Jeffrey Campbell / St. Joseph’s London.",
                content: """
                Questions about the study: contact your site investigator. \
                Site code and study code appear in Settings. Replace this stub with IRB-approved \
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

        let visual = ORKVisualConsentStep(identifier: "consent.visual", document: document)

        let comprehension = ORKQuestionStep(
            identifier: "consent.comprehension",
            title: "Comprehension",
            question: "This study is primarily:",
            answer: ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
                ORKTextChoice(text: "Observational (not a treatment program)", value: "observational" as NSString),
                ORKTextChoice(text: "A new drug trial", value: "drug" as NSString),
                ORKTextChoice(text: "Diagnostic testing", value: "dx" as NSString)
            ])
        )
        comprehension.text = "Please confirm you understand the study type before signing."

        let review = ORKConsentReviewStep(identifier: "consent.review", signature: nil, in: document)
        review.reasonForConsent = "I agree to join this observational study of Xialla use."

        return ORKOrderedTask(identifier: "xialla.consent", steps: [visual, comprehension, review])
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
            ? "Complete these before first use when possible. IIEF-5 items use a 1–5 slider (starts at 3)."
            : "Week‑4 follow-up. IIEF-5 items use a 1–5 slider (starts at 3)."
        steps.append(intro)

        steps.append(iief5Form(timepoint: timepoint))

        if timepoint == .baseline {
            steps.append(baselineHistoryForm())
        }

        steps.append(likertForm(
            id: "\(timepoint.rawValue).usability",
            title: "Usability",
            prompt: "How easy was Xialla to use?",
            low: "Very difficult",
            high: "Very easy"
        ))
        steps.append(likertForm(
            id: "\(timepoint.rawValue).comfort",
            title: "Comfort",
            prompt: "How comfortable was Xialla to wear?",
            low: "Very uncomfortable",
            high: "Very comfortable"
        ))
        steps.append(likertForm(
            id: "\(timepoint.rawValue).satisfaction",
            title: "Satisfaction",
            prompt: "Overall, how satisfied are you with Xialla?",
            low: "Very dissatisfied",
            high: "Very satisfied"
        ))
        steps.append(adverseEventsForm(timepoint: timepoint))
        steps.append(freeTextForm(timepoint: timepoint))

        let done = ORKCompletionStep(identifier: "survey.\(timepoint.rawValue).done")
        done.title = "Saved"
        done.text = "Responses stay on-device until the API syncs. IIEF-5 total is scored locally (5–25)."
        steps.append(done)

        return ORKOrderedTask(identifier: "xialla.survey.\(timepoint.rawValue)", steps: steps)
    }

    /// IIEF-5: five horizontal scale sliders, range 1–5, **default 3**.
    /// Item wording is paraphrased placeholder until licensing is cleared.
    private static func iief5Form(timepoint: SurveyTimepoint) -> ORKFormStep {
        let step = ORKFormStep(
            identifier: "iief5.\(timepoint.rawValue)",
            title: "IIEF-5",
            text: """
            Rate each item from 1 (lowest) to 5 (highest). Sliders start at 3. \
            Official IIEF-5 wording must be cleared for licensing before shipping final copy.
            """
        )
        let prompts = IIEF5Scoring.placeholderPrompts
        var items: [ORKFormItem] = []
        for (index, prompt) in prompts.enumerated() {
            let q = index + 1
            let format = ORKScaleAnswerFormat(
                maximumValue: 5,
                minimumValue: 1,
                defaultValue: 3,
                step: 1,
                vertical: false,
                maximumValueDescription: "5",
                minimumValueDescription: "1"
            )
            let item = ORKFormItem(
                identifier: "iief5.q\(q)",
                text: "\(q). \(prompt)",
                answerFormat: format
            )
            items.append(item)
        }
        step.formItems = items
        return step
    }

    private static func baselineHistoryForm() -> ORKFormStep {
        let step = ORKFormStep(
            identifier: "baseline.history",
            title: "Baseline history",
            text: "Brief history before first study use of Xialla."
        )
        step.formItems = [
            ORKFormItem(
                identifier: "baseline.history.prior_ed_tx",
                text: "Have you used other ED treatments before?",
                answerFormat: ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
                    ORKTextChoice(text: "Yes", value: "yes" as NSString),
                    ORKTextChoice(text: "No", value: "no" as NSString),
                    ORKTextChoice(text: "Prefer not to say", value: "na" as NSString)
                ])
            ),
            ORKFormItem(
                identifier: "baseline.history.notes",
                text: "Anything else relevant for the study team?",
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
            text: "Report any problems related to Xialla use since the last questionnaire."
        )
        step.formItems = [
            ORKFormItem(
                identifier: "\(id).any",
                text: "Did you experience any adverse events?",
                answerFormat: ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
                    ORKTextChoice(text: "No", value: "no" as NSString),
                    ORKTextChoice(text: "Yes", value: "yes" as NSString)
                ])
            ),
            ORKFormItem(
                identifier: "\(id).detail",
                text: "If yes, briefly describe:",
                answerFormat: ORKTextAnswerFormat(maximumLength: 500)
            )
        ]
        return step
    }

    private static func freeTextForm(timepoint: SurveyTimepoint) -> ORKFormStep {
        let id = "\(timepoint.rawValue).freeText"
        let step = ORKFormStep(
            identifier: id,
            title: "Free text",
            text: "Optional comments for the study team."
        )
        step.formItems = [
            ORKFormItem(
                identifier: "\(id).note",
                text: "Comments",
                answerFormat: ORKTextAnswerFormat(maximumLength: 800)
            )
        ]
        return step
    }
}

#endif
