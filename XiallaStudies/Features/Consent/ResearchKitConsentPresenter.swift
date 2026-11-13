import SwiftUI

#if canImport(ResearchKit) && canImport(ResearchKitUI)
import ResearchKit
import ResearchKitUI

/// Presents an `ORKTaskViewController` for eConsent (info → comprehension stub → signature).
struct ResearchKitConsentPresenter: UIViewControllerRepresentable {
    var onFinish: () -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> ORKTaskViewController {
        let task = ResearchKitTaskFactory.makeConsentTask()
        let vc = ORKTaskViewController(task: task, taskRun: nil)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: ORKTaskViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish, onCancel: onCancel)
    }

    final class Coordinator: NSObject, ORKTaskViewControllerDelegate {
        let onFinish: () -> Void
        let onCancel: () -> Void

        init(onFinish: @escaping () -> Void, onCancel: @escaping () -> Void) {
            self.onFinish = onFinish
            self.onCancel = onCancel
        }

        func taskViewController(
            _ taskViewController: ORKTaskViewController,
            didFinishWith reason: ORKTaskViewControllerFinishReason,
            error: Error?
        ) {
            taskViewController.dismiss(animated: true) {
                if reason == .completed {
                    self.onFinish()
                } else {
                    self.onCancel()
                }
            }
        }
    }
}

enum ResearchKitTaskFactory {
    static func makeConsentTask() -> ORKOrderedTask {
        let document = ORKConsentDocument()
        document.title = "Xialla Observational Study"
        document.sections = [
            section(.overview, title: "Overview", summary: "Stub overview pending IRB-approved copy."),
            section(.dataGathering, title: "Data", summary: "Survey responses are stored with study_code and site_code."),
            section(.privacy, title: "Privacy", summary: "Stub privacy section — replace with approved language."),
            section(.withdrawing, title: "Withdrawal", summary: "You may withdraw at any time from Settings.")
        ]

        let signature = ORKConsentSignature(
            forPersonWithTitle: "Participant",
            dateFormatString: nil,
            identifier: "participant.signature"
        )
        document.addSignature(signature)

        let review = ORKConsentReviewStep(identifier: "consent.review", signature: nil, in: document)
        review.reasonForConsent = "I agree to join this observational study."

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

        let visual = ORKVisualConsentStep(identifier: "consent.visual", document: document)
        return ORKOrderedTask(identifier: "xialla.consent", steps: [visual, comprehension, review])
    }

    private static func section(
        _ type: ORKConsentSectionType,
        title: String,
        summary: String
    ) -> ORKConsentSection {
        let section = ORKConsentSection(type: type)
        section.title = title
        section.summary = summary
        section.content = summary + "\n\nFull IRB text will replace this stub."
        return section
    }

    /// IIEF-5 + companion instruments as ResearchKit form stubs.
    /// IIEF-5 item wording must be cleared for licensing before shipping final copy.
    static func makeSurveyTask(timepoint: SurveyTimepoint) -> ORKOrderedTask {
        var steps: [ORKStep] = []

        let intro = ORKInstructionStep(identifier: "survey.\(timepoint.rawValue).intro")
        intro.title = timepoint.displayName
        intro.detailText = "Instrument stubs — replace with cleared wording."
        steps.append(intro)

        steps.append(iief5Form(timepoint: timepoint))

        if timepoint == .baseline {
            steps.append(simpleForm(
                id: "baseline.history",
                title: "Baseline history",
                prompt: "Brief history stub (replace with protocol items)."
            ))
        }

        for code in [InstrumentCode.usability, .comfort, .satisfaction, .adverseEvents, .freeText] {
            steps.append(simpleForm(
                id: "\(timepoint.rawValue).\(code.rawValue)",
                title: code.displayName,
                prompt: "\(code.displayName) stub items for \(timepoint.displayName)."
            ))
        }

        let done = ORKCompletionStep(identifier: "survey.\(timepoint.rawValue).done")
        done.title = "Saved"
        done.text = "Responses stay on-device until the API syncs."
        steps.append(done)

        return ORKOrderedTask(identifier: "xialla.survey.\(timepoint.rawValue)", steps: steps)
    }

    private static func iief5Form(timepoint: SurveyTimepoint) -> ORKFormStep {
        let step = ORKFormStep(
            identifier: "iief5.\(timepoint.rawValue)",
            title: "IIEF-5",
            text: "Licensing: do not ship copyrighted item wording without clearance. Placeholder scales only."
        )
        var items: [ORKFormItem] = []
        for i in 1...5 {
            let format = ORKScaleAnswerFormat(
                maximumValue: 5,
                minimumValue: 1,
                defaultValue: 3,
                step: 1,
                vertical: false,
                maximumValueDescription: "High",
                minimumValueDescription: "Low"
            )
            let item = ORKFormItem(
                identifier: "iief5.q\(i)",
                text: "IIEF-5 item \(i) (placeholder)",
                answerFormat: format
            )
            items.append(item)
        }
        step.formItems = items
        return step
    }

    private static func simpleForm(id: String, title: String, prompt: String) -> ORKFormStep {
        let step = ORKFormStep(identifier: id, title: title, text: prompt)
        let item = ORKFormItem(
            identifier: "\(id).note",
            text: "Notes",
            answerFormat: ORKTextAnswerFormat(maximumLength: 500)
        )
        step.formItems = [item]
        return step
    }
}

#else

/// Fallback when ResearchKit is not yet linked — branded SwiftUI consent still works.
struct ResearchKitConsentPresenter: View {
    var onFinish: () -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("ResearchKit not linked")
                    .font(BrandTheme.display(24, weight: .medium))
                Text("Add ResearchKit + ResearchKitUI to the Xcode target (see README). Until then, use the in-app consent stubs.")
                    .font(BrandTheme.body(15))
                    .foregroundStyle(BrandTheme.graphite)
                Spacer()
                PrimaryButton(title: "Continue without ResearchKit UI") {
                    onFinish()
                }
                SecondaryButton(title: "Cancel") {
                    onCancel()
                }
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onCancel)
                }
            }
        }
    }
}

#endif
