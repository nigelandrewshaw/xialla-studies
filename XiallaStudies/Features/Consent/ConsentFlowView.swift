import SwiftUI

/// Branded consent bookends. ResearchKit task is presented from `ResearchKitConsentPresenter`.
struct ConsentFlowView: View {
    @EnvironmentObject private var session: StudySession
    @State private var step: Step = .intro
    @State private var comprehensionAnswer: ComprehensionChoice?
    @State private var signatureName = ""
    @State private var showResearchKitTask = false

    enum Step {
        case intro
        case info
        case comprehension
        case signature
        case done
    }

    enum ComprehensionChoice: String, CaseIterable, Identifiable {
        case observational
        case treatment
        case diagnosis

        var id: String { rawValue }

        var label: String {
            switch self {
            case .observational: return "An observational study of Xialla use"
            case .treatment: return "A treatment program that diagnoses ED"
            case .diagnosis: return "A clinical trial of a new drug"
            }
        }

        var isCorrect: Bool { self == .observational }
    }

    var body: some View {
        ZStack {
            AtmosphereBackground()

            VStack(alignment: .leading, spacing: 24) {
                content
                Spacer(minLength: 0)
                footer
            }
            .padding(24)
        }
        .navigationTitle("Consent")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showResearchKitTask) {
            ResearchKitConsentPresenter {
                showResearchKitTask = false
                step = .comprehension
            } onCancel: {
                showResearchKitTask = false
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .intro:
            SectionIntro(
                headline: "What you’re agreeing to",
                support: "You’ll review study information, answer a short comprehension check, and sign if you choose to join. You can withdraw later from Settings."
            )
        case .info:
            SectionIntro(
                headline: "Study information",
                support: "Purpose, procedures, risks/benefits, data use, and withdrawal — stub copy until IRB-approved text is wired into ResearchKit consent sections."
            )
            VStack(alignment: .leading, spacing: 10) {
                infoLine("Prospective observational study (not a clinical trial app).")
                infoLine("Baseline questionnaires before first use; week‑4 follow-up.")
                infoLine("Data tagged with study_code and site_code.")
                infoLine("Contact the site team to ask questions before signing.")
            }
        case .comprehension:
            SectionIntro(
                headline: "Comprehension check",
                support: "Stub question — replace with IRB-approved items."
            )
            VStack(spacing: 10) {
                Text("This app is for:")
                    .font(BrandTheme.body(15, weight: .medium))
                    .foregroundStyle(BrandTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(ComprehensionChoice.allCases) { choice in
                    Button {
                        comprehensionAnswer = choice
                    } label: {
                        HStack {
                            Text(choice.label)
                                .font(BrandTheme.body(15))
                                .foregroundStyle(BrandTheme.ink)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if comprehensionAnswer == choice {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(BrandTheme.teal)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    comprehensionAnswer == choice ? BrandTheme.teal : BrandTheme.mist,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        case .signature:
            SectionIntro(
                headline: "Signature",
                support: "Type your name to stub a signature. On device, ResearchKit captures a drawn signature."
            )
            TextField("Full name", text: $signatureName)
                .textContentType(.name)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(BrandTheme.parchment)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(BrandTheme.mist, lineWidth: 1)
                        )
                )
        case .done:
            SectionIntro(
                headline: "Consent saved locally",
                support: "Version \(StudyConfig.consentDocumentVersion). Sync to Cloud Run when the API is live."
            )
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch step {
        case .intro:
            VStack(spacing: 12) {
                PrimaryButton(title: "Review information") {
                    step = .info
                }
                SecondaryButton(title: "Open ResearchKit consent task") {
                    showResearchKitTask = true
                }
            }
        case .info:
            PrimaryButton(title: "Continue to comprehension") {
                step = .comprehension
            }
        case .comprehension:
            PrimaryButton(
                title: "Continue",
                enabled: comprehensionAnswer?.isCorrect == true
            ) {
                step = .signature
            }
        case .signature:
            PrimaryButton(title: "Sign & join", enabled: !signatureName.trimmingCharacters(in: .whitespaces).isEmpty) {
                Task {
                    await session.completeConsent(
                        comprehensionPassed: true,
                        signatureBlobRef: "local-stub:\(signatureName)"
                    )
                    step = .done
                }
            }
        case .done:
            PrimaryButton(title: "Continue to baseline") {
                session.path.append(.baselineSurveys)
            }
        }
    }

    private func infoLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(BrandTheme.teal)
                .frame(width: 6, height: 6)
                .padding(.top, 7)
            Text(text)
                .font(BrandTheme.body(15))
                .foregroundStyle(BrandTheme.graphite)
        }
    }
}
