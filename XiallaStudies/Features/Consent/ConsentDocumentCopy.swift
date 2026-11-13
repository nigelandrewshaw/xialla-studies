import Foundation

/// Prospective observational study consent copy for the native branded flow.
/// Stub language — replace with IRB-approved text before enrollment.
enum ConsentDocumentCopy {
    static let documentTitle = "Xialla Observational Study"

    struct Section: Identifiable, Equatable {
        let id: String
        let title: String
        let summary: String
        let body: String
    }

    /// Multi-section review order: purpose → procedures → data use → risks/benefits → voluntary.
    static let reviewSections: [Section] = [
        Section(
            id: "purpose",
            title: "Purpose",
            summary: "This is a prospective observational study of Xialla use among men.",
            body: """
            You are being invited to take part in an observational study of Xialla. \
            The study looks at how erectile function (IIEF-5) and related experiences \
            change over about four weeks of real-world use. This is not a treatment program, \
            drug trial, or diagnostic service. Participation is voluntary.
            """
        ),
        Section(
            id: "procedures",
            title: "Procedures",
            summary: "You will complete baseline questionnaires before first use, then a week‑4 follow-up.",
            body: """
            If you join, you will: (1) confirm eligibility, (2) complete baseline surveys \
            including the IIEF-5 and brief history, usability, comfort, satisfaction, and \
            adverse-event questions, (3) use Xialla as you normally would, and (4) complete \
            a week‑4 follow-up in the app. Optional local reminders help you remember the follow-up. \
            Records are tagged with study_code and site_code for the coordinating site.
            """
        ),
        Section(
            id: "dataUse",
            title: "Data use",
            summary: "Survey answers and consent metadata are stored for the study.",
            body: """
            We collect questionnaire responses, consent status, timestamps, and study/site codes. \
            Data stay on your device until a secure sync to the study cloud database is available. \
            De-identified aggregate results may be used for research reporting. We do not sell your data.
            """
        ),
        Section(
            id: "risksBenefits",
            title: "Risks and benefits",
            summary: "Sexual-health answers are sensitive, and a residual privacy risk remains.",
            body: """
            Sexual health information is sensitive. We apply technical safeguards appropriate for a \
            HIPAA-oriented study environment when syncing. Risks include discomfort answering personal \
            questions and residual privacy risk if a device is lost or compromised. Benefits include \
            contributing to understanding of Xialla use; there is no guarantee of personal medical benefit.
            """
        ),
        Section(
            id: "voluntary",
            title: "Voluntary participation and withdrawal",
            summary: "You may withdraw at any time from Settings.",
            body: """
            Participation is voluntary. You can stop at any time without penalty by using Withdraw in Settings. \
            Data already collected may remain in the study dataset as permitted by the protocol \
            and ethics approval. Contact the site team with questions before or after signing. \
            The site investigator is \(StudyConfig.provider.displayName) at \(StudyConfig.provider.organization).
            """
        )
    ]

    static let reasonForConsent =
        "I agree to join this observational study of Xialla use."

    static let comprehensionPrompt =
        "Which of the following best describes this study?"
}
