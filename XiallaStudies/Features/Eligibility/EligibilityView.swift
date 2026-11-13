import SwiftUI

/// Prospective-first eligibility. Current-user add-on is visible but disabled in v1.
struct EligibilityView: View {
    @EnvironmentObject private var session: StudySession

    var body: some View {
        ZStack {
            AtmosphereBackground()

            VStack(alignment: .leading, spacing: 28) {
                SectionIntro(
                    headline: "Who is this study for?",
                    support: "This version enrolls people who are starting Xialla. A separate path for people who already use Xialla may be added later."
                )

                VStack(spacing: 14) {
                    armCard(
                        title: StudyArm.prospective.displayName,
                        detail: "You will complete baseline questionnaires before first use, then return for a week‑4 follow-up.",
                        enabled: true
                    ) {
                        Task { await session.selectProspectiveArm() }
                    }

                    armCard(
                        title: StudyArm.currentUserAddOn.displayName,
                        detail: "This optional path for current users is not available yet and is pending protocol owner approval.",
                        enabled: false
                    ) {}
                }

                Spacer()
            }
            .padding(24)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func armCard(
        title: String,
        detail: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(BrandTheme.body(18, weight: .semibold))
                        .foregroundStyle(enabled ? BrandTheme.ink : BrandTheme.graphite.opacity(0.6))
                    Spacer()
                    if !enabled {
                        StatusChip(text: "Later", tone: .neutral)
                    }
                }
                Text(detail)
                    .font(BrandTheme.body(15))
                    .foregroundStyle(BrandTheme.graphite)
                    .multilineTextAlignment(.leading)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(BrandTheme.chalk.opacity(0.92))
                    .shadow(color: BrandTheme.ink.opacity(0.06), radius: 12, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(enabled ? BrandTheme.tan.opacity(0.7) : BrandTheme.mist, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityHint(enabled ? "Double tap to continue" : "Not available in this version")
    }
}
