import SwiftUI

/// Prospective-first eligibility. Current-user add-on is visible but disabled in v1.
struct EligibilityView: View {
    @EnvironmentObject private var session: StudySession

    var body: some View {
        ZStack {
            AtmosphereBackground()

            VStack(alignment: .leading, spacing: 28) {
                SectionIntro(
                    headline: "Who is this for?",
                    support: "This version enrolls people who are starting Xialla. A path for current users may be added later."
                )

                VStack(spacing: 14) {
                    armCard(
                        title: StudyArm.prospective.displayName,
                        detail: "Baseline before first use, then a week‑4 follow-up.",
                        enabled: true
                    ) {
                        Task { await session.selectProspectiveArm() }
                    }

                    armCard(
                        title: StudyArm.currentUserAddOn.displayName,
                        detail: "Optional add-on — pending protocol owner approval.",
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
                    .fill(BrandTheme.parchment.opacity(0.9))
                    .shadow(color: BrandTheme.ink.opacity(0.06), radius: 12, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(enabled ? BrandTheme.teal.opacity(0.35) : BrandTheme.mist, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityHint(enabled ? "Double tap to continue" : "Not available in this version")
    }
}
