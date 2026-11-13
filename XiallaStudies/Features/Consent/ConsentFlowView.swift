import PencilKit
import SwiftUI

/// Native branded multi-step eConsent — no ResearchKit.
/// Sections: purpose → procedures → data use → risks/benefits → voluntary →
/// comprehension → name + signature pad + date.
struct ConsentFlowView: View {
    @EnvironmentObject private var session: StudySession

    @State private var step: Step = .intro
    @State private var sectionIndex = 0
    @State private var comprehensionAnswer: ComprehensionChoice?
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var signatureDrawing = PKDrawing()
    @State private var signatureHasInk = false
    @State private var isSaving = false
    @State private var saveError: String?

    private let signaturePadSize = CGSize(width: 320, height: 160)
    private let signedAt = Date()

    /// Body copy one point above the prior 15pt stubs for readability.
    private let bodyPointSize: CGFloat = 16

    enum Step: Equatable {
        case intro
        case review
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
            case .observational:
                return "An observational study of Xialla use (not a treatment program)"
            case .treatment:
                return "A treatment program that diagnoses erectile dysfunction"
            case .diagnosis:
                return "A clinical trial of a new drug"
            }
        }

        var isCorrect: Bool { self == .observational }
    }

    private var sections: [ConsentDocumentCopy.Section] {
        ConsentDocumentCopy.reviewSections
    }

    private var currentSection: ConsentDocumentCopy.Section {
        sections[min(sectionIndex, max(sections.count - 1, 0))]
    }

    private var canSign: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && signatureHasInk
            && !isSaving
    }

    var body: some View {
        ZStack {
            AtmosphereBackground()

            VStack(spacing: 0) {
                if step == .signature {
                    // Keep the PencilKit pad outside ScrollView so finger/Pencil strokes are not stolen.
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 20) {
                            signatureHeaderFields
                        }
                        .padding(.horizontal, BrandTheme.contentInset)
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    signaturePadBlock
                        .padding(.horizontal, BrandTheme.contentInset)
                        .padding(.bottom, 8)
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 20) {
                            content
                        }
                        .padding(.horizontal, BrandTheme.contentInset)
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                footer
                    .padding(.horizontal, BrandTheme.contentInset)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                    .background(BrandTheme.canvas.opacity(0.96))
            }
        }
        .navigationTitle("Consent")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch step {
        case .intro:
            SectionIntro(
                headline: "What you are agreeing to",
                support: "You will review study information in several short screens, answer a comprehension check, then type your name and sign if you choose to join. Your progress is saved on this device."
            )
            providerChip

        case .review:
            // No icon / header overlays — title + scrollable body only.
            Text(currentSection.title)
                .font(BrandTheme.display(28, weight: .medium))
                .foregroundStyle(BrandTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(currentSection.summary)
                .font(BrandTheme.body(bodyPointSize, weight: .medium))
                .foregroundStyle(BrandTheme.graphite)
                .fixedSize(horizontal: false, vertical: true)

            Text(currentSection.body)
                .font(BrandTheme.body(bodyPointSize))
                .foregroundStyle(BrandTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)

            Text("Section \(sectionIndex + 1) of \(sections.count)")
                .font(BrandTheme.body(13))
                .foregroundStyle(BrandTheme.graphite)
                .padding(.top, 8)

        case .comprehension:
            SectionIntro(
                headline: "Comprehension check",
                support: "Please confirm that you understand what kind of study this is before you continue."
            )
            Text(ConsentDocumentCopy.comprehensionPrompt)
                .font(BrandTheme.body(bodyPointSize, weight: .medium))
                .foregroundStyle(BrandTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(ComprehensionChoice.allCases) { choice in
                    Button {
                        comprehensionAnswer = choice
                    } label: {
                        HStack(alignment: .top) {
                            Text(choice.label)
                                .font(BrandTheme.body(bodyPointSize))
                                .foregroundStyle(BrandTheme.ink)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
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
            EmptyView()

        case .done:
            SectionIntro(
                headline: "Consent saved locally",
                support: "Your consent (document version \(StudyConfig.consentDocumentVersion)) and signature are saved on this device. You can quit and reopen the app without losing this progress."
            )
        }
    }

    private var signatureHeaderFields: some View {
        Group {
            SectionIntro(
                headline: "Sign to join",
                support: ConsentDocumentCopy.reasonForConsent
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("First name")
                    .font(BrandTheme.body(13, weight: .medium))
                    .foregroundStyle(BrandTheme.graphite)
                TextField("First name", text: $firstName)
                    .textContentType(.givenName)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(fieldChrome)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Last name")
                    .font(BrandTheme.body(13, weight: .medium))
                    .foregroundStyle(BrandTheme.graphite)
                TextField("Last name", text: $lastName)
                    .textContentType(.familyName)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(fieldChrome)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Date")
                    .font(BrandTheme.body(13, weight: .medium))
                    .foregroundStyle(BrandTheme.graphite)
                Text(formattedDate(signedAt))
                    .font(BrandTheme.body(bodyPointSize))
                    .foregroundStyle(BrandTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(fieldChrome)
            }

            if let saveError {
                Text(saveError)
                    .font(BrandTheme.body(14))
                    .foregroundStyle(BrandTheme.attention)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var signaturePadBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Signature")
                    .font(BrandTheme.body(13, weight: .medium))
                    .foregroundStyle(BrandTheme.graphite)
                Spacer()
                Button("Clear") {
                    signatureDrawing = PKDrawing()
                    signatureHasInk = false
                }
                .font(BrandTheme.body(13, weight: .medium))
                .foregroundStyle(BrandTheme.ink)
                .disabled(!signatureHasInk)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white.opacity(0.85))
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(BrandTheme.mist, lineWidth: 1)
                if !signatureHasInk {
                    Text("Sign with finger or Apple Pencil")
                        .font(BrandTheme.body(14))
                        .foregroundStyle(BrandTheme.graphite.opacity(0.7))
                        .allowsHitTesting(false)
                }
                SignaturePadView(drawing: $signatureDrawing) { drawing in
                    signatureHasInk = drawing.hasInk
                }
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
            .frame(height: signaturePadSize.height)
        }
    }

    private var fieldChrome: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(Color.white.opacity(0.7))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(BrandTheme.mist, lineWidth: 1)
            )
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

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        switch step {
        case .intro:
            PrimaryButton(title: "Review study information") {
                sectionIndex = 0
                step = .review
            }
        case .review:
            HStack(spacing: 12) {
                if sectionIndex > 0 {
                    SecondaryButton(title: "Back") {
                        sectionIndex -= 1
                    }
                }
                PrimaryButton(
                    title: sectionIndex + 1 < sections.count ? "Continue" : "Continue to comprehension"
                ) {
                    if sectionIndex + 1 < sections.count {
                        sectionIndex += 1
                    } else {
                        step = .comprehension
                    }
                }
            }
        case .comprehension:
            PrimaryButton(
                title: "Continue to signature",
                enabled: comprehensionAnswer?.isCorrect == true
            ) {
                step = .signature
            }
        case .signature:
            PrimaryButton(title: isSaving ? "Saving…" : "Sign & join", enabled: canSign) {
                Task { await saveAndComplete() }
            }
        case .done:
            PrimaryButton(title: "Continue to baseline") {
                session.path.append(.baselineSurveys)
            }
        }
    }

    // MARK: - Persist

    private func saveAndComplete() async {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        let given = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let family = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard signatureHasInk,
              let png = signatureDrawing.pngData(padSize: signaturePadSize)
        else {
            saveError = "Please add your signature before continuing."
            return
        }

        do {
            let saved = try ConsentSignatureStore.saveSignaturePNG(png)
            let pdfURL = ConsentSignatureStore.exportPDF(
                firstName: given,
                lastName: family,
                signedAt: signedAt,
                signaturePNG: png
            )
            let ref = "\(saved.ref)|\(given) \(family)"
            await session.completeConsent(
                comprehensionPassed: true,
                signatureBlobRef: ref,
                pdfURL: pdfURL,
                navigateToBaseline: false
            )
            step = .done
        } catch {
            saveError = "Could not save your signature on this device. Please try again."
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
