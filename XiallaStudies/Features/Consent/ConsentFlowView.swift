import SwiftUI

/// Branded consent bookends + ResearchKit task (or SwiftUI fallback).
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
            case .observational: return "An observational study of Xialla use (not a treatment program)"
            case .treatment: return "A treatment program that diagnoses erectile dysfunction"
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
            ResearchKitConsentPresenter { signatureRef, pdfURL, comprehensionPassed in
                showResearchKitTask = false
                guard comprehensionPassed else {
                    // Wrong comprehension answer — return to the in-app check.
                    step = .comprehension
                    return
                }
                Task {
                    await session.completeConsent(
                        comprehensionPassed: true,
                        signatureBlobRef: signatureRef,
                        pdfURL: pdfURL
                    )
                    step = .done
                }
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
                headline: "What you are agreeing to",
                support: "You will review study information, answer a short comprehension check, and sign if you choose to join. Your progress is saved on this device."
            )
            providerChip
        case .info:
            SectionIntro(
                headline: "Study information",
                support: "Please review the purpose, procedures, risks and benefits, data use, and withdrawal options for this observational study. IRB-approved language can replace these stubs later."
            )
            VStack(alignment: .leading, spacing: 10) {
                infoLine("This is a prospective observational study of Xialla use, not a treatment program.")
                infoLine("You will complete baseline questionnaires before first use, then a week‑4 follow-up.")
                infoLine("Your records are tagged with a study_code and site_code for the coordinating site.")
                infoLine("The site investigator is \(StudyConfig.provider.displayName).")
            }
        case .comprehension:
            SectionIntro(
                headline: "Comprehension check",
                support: "Please confirm that you understand what kind of study this is before you continue."
            )
            VStack(spacing: 10) {
                Text("Which of the following best describes this study?")
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
                                    .foregroundStyle(BrandTheme.ink)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(
                                    comprehensionAnswer == choice ? BrandTheme.ink : BrandTheme.mist,
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
                support: "Please type your full name to record consent on this device. When ResearchKit is linked, a drawn signature and PDF export are used instead."
            )
            TextField("Full name", text: $signatureName)
                .textContentType(.name)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(BrandTheme.mist, lineWidth: 1)
                        )
                )
        case .done:
            SectionIntro(
                headline: "Consent saved locally",
                support: "Your consent (document version \(StudyConfig.consentDocumentVersion)) is saved on this device. You can quit and reopen the app without losing this progress."
            )
        }
    }

    private var providerChip: some View {
        HStack(spacing: 12) {
            if let asset = StudyConfig.provider.photoAssetName {
                Image(asset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipped()
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(StudyConfig.provider.displayName)
                    .font(BrandTheme.body(14, weight: .semibold))
                Text(StudyConfig.provider.organization)
                    .font(BrandTheme.body(12))
                    .foregroundStyle(BrandTheme.graphite)
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private var footer: some View {
        switch step {
        case .intro:
            VStack(spacing: 12) {
                PrimaryButton(title: "Continue with ResearchKit consent") {
                    showResearchKitTask = true
                }
                SecondaryButton(title: "Review study information in the app") {
                    step = .info
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
                .fill(BrandTheme.tan)
                .frame(width: 6, height: 6)
                .padding(.top, 7)
            Text(text)
                .font(BrandTheme.body(15))
                .foregroundStyle(BrandTheme.graphite)
        }
    }
}
