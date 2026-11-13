import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: StudySession
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .top) {
            AtmosphereBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroBand

                    VStack(alignment: .leading, spacing: 28) {
                        statusBlock
                        if let summary = session.lastIIEF5Summary {
                            Text(summary)
                                .font(BrandTheme.body(15, weight: .semibold))
                                .foregroundStyle(BrandTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if let iief = session.snapshot.surveys.last(where: { $0.instrument == .iief5 }),
                                  let total = iief.scoreTotal {
                            Text("Latest IIEF-5 \(total)" + (iief.scoreBand.map { " (\($0))" } ?? ""))
                                .font(BrandTheme.body(15, weight: .semibold))
                                .foregroundStyle(BrandTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        nextAction
                        providerLink
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, BrandTheme.contentInset)
                    .padding(.top, 28)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .ignoresSafeArea(edges: .top)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    session.showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(BrandTheme.ink)
                }
                .accessibilityLabel("Settings")
            }
        }
        .onAppear {
            withAnimation(BrandTheme.reveal) {
                appeared = true
            }
        }
    }

    /// Full-bleed brand hero — logo over product imagery; status copy sits below.
    private var heroBand: some View {
        Color.clear
            .frame(height: 280)
            .frame(maxWidth: .infinity)
            .overlay {
                GeometryReader { geo in
                    ZStack(alignment: .bottomLeading) {
                        Image("HomeHero")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()

                        LinearGradient(
                            colors: [
                                .clear,
                                BrandTheme.ink.opacity(0.45),
                                BrandTheme.ink.opacity(0.82)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        Button {
                            session.presentBrandSplash()
                        } label: {
                            BrandWordmark(size: 40, light: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Xialla")
                        .accessibilityHint("Shows the welcome splash screen")
                        .padding(.leading, BrandTheme.contentInset)
                        .padding(.trailing, BrandTheme.contentInset)
                        .padding(.bottom, 28)
                        .opacity(appeared ? 1 : 0)
                    }
                }
            }
            .clipped()
            .accessibilityElement(children: .contain)
    }

    private var statusBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(statusHeadline)
                .font(BrandTheme.display(26, weight: .medium))
                .foregroundStyle(BrandTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(statusSupport)
                .font(BrandTheme.body(16))
                .foregroundStyle(BrandTheme.graphite)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    statusChips
                }
                VStack(alignment: .leading, spacing: 8) {
                    statusChips
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var statusChips: some View {
        StatusChip(text: chipLabel, tone: chipTone)
        if let due = session.enrollment?.followUpDueAt {
            StatusChip(
                text: "Due \(due.formatted(date: .abbreviated, time: .omitted))",
                tone: session.status == .followUpDue ? .due : .neutral
            )
        }
    }

    @ViewBuilder
    private var nextAction: some View {
        switch session.status {
        case .notStarted:
            PrimaryButton(title: "Check eligibility") {
                session.beginEligibility()
            }
        case .eligible:
            PrimaryButton(title: "Continue to consent") {
                session.path.append(.consent)
            }
        case .consented:
            PrimaryButton(title: "Start baseline surveys") {
                session.path.append(.baselineSurveys)
            }
        case .baselineComplete:
            VStack(alignment: .leading, spacing: 12) {
                Text("We’ll remind you at week 4. You can keep using Xialla as usual. Progress is saved if you quit.")
                    .font(BrandTheme.body(15))
                    .foregroundStyle(BrandTheme.graphite)
                    .fixedSize(horizontal: false, vertical: true)
                SecondaryButton(title: "Reminder settings") {
                    session.path.append(.reminders)
                }
                SecondaryButton(title: "Demo: jump to week 4") {
                    Task { await session.demoAdvanceToWeek4() }
                }
            }
        case .followUpDue:
            PrimaryButton(title: "Start week‑4 follow-up") {
                session.startWeek4FollowUp()
            }
        case .completed:
            Text("Thank you — your study participation is complete.")
                .font(BrandTheme.body(16))
                .foregroundStyle(BrandTheme.graphite)
                .fixedSize(horizontal: false, vertical: true)
        case .withdrawn:
            Text("You have withdrawn from the study.")
                .font(BrandTheme.body(16))
                .foregroundStyle(BrandTheme.graphite)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statusHeadline: String {
        switch session.status {
        case .notStarted: return "Join the study"
        case .eligible: return "You’re eligible"
        case .consented: return "Consent recorded"
        case .baselineComplete: return "Baseline complete"
        case .followUpDue: return "Follow-up ready"
        case .completed: return "All done"
        case .withdrawn: return "Withdrawn"
        }
    }

    private var statusSupport: String {
        switch session.status {
        case .notStarted:
            return "Prospective participants complete a short baseline, then a week‑4 follow-up."
        case .eligible:
            return "Next: review consent and sign if you agree."
        case .consented:
            return "A few short questionnaires before first use."
        case .baselineComplete:
            return "Your week‑4 check-in is scheduled. No action needed until then."
        case .followUpDue:
            return "Please complete your week‑4 questionnaires when you can."
        case .completed:
            return "Your responses help improve understanding of Xialla use."
        case .withdrawn:
            return "You can contact the study team from Settings if needed."
        }
    }

    private var chipLabel: String {
        switch session.status {
        case .notStarted: return "Not enrolled"
        case .eligible: return "Eligible"
        case .consented: return "Consented"
        case .baselineComplete: return "Active"
        case .followUpDue: return "Action needed"
        case .completed: return "Completed"
        case .withdrawn: return "Withdrawn"
        }
    }

    private var chipTone: StatusChip.Tone {
        switch session.status {
        case .notStarted, .eligible, .consented: return .active
        case .baselineComplete: return .active
        case .followUpDue: return .due
        case .completed: return .done
        case .withdrawn: return .neutral
        }
    }

    private var providerLink: some View {
        Button {
            session.path.append(.provider)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                if let asset = StudyConfig.provider.photoAssetName {
                    Image(asset)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(BrandTheme.ink.opacity(0.12), lineWidth: 1)
                        )
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(StudyConfig.provider.displayName)
                        .font(BrandTheme.body(15, weight: .semibold))
                        .foregroundStyle(BrandTheme.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Study investigator · \(StudyConfig.provider.location)")
                        .font(BrandTheme.body(13))
                        .foregroundStyle(BrandTheme.graphite)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
                Image(systemName: "chevron.right")
                    .foregroundStyle(BrandTheme.graphite)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Study investigator profile")
    }
}
