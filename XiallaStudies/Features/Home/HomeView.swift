import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: StudySession
    @State private var appeared = false

    var body: some View {
        ZStack {
            AtmosphereBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    statusBlock

                    nextAction

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
            }
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            BrandWordmark(size: 32)
            Text("Observational study")
                .font(BrandTheme.body(15))
                .foregroundStyle(BrandTheme.graphite)
        }
    }

    private var statusBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(statusHeadline)
                .font(BrandTheme.display(26, weight: .medium))
                .foregroundStyle(BrandTheme.ink)
            Text(statusSupport)
                .font(BrandTheme.body(16))
                .foregroundStyle(BrandTheme.graphite)

            HStack(spacing: 8) {
                StatusChip(text: chipLabel, tone: chipTone)
                if let due = session.enrollment?.followUpDueAt {
                    StatusChip(
                        text: "Due \(due.formatted(date: .abbreviated, time: .omitted))",
                        tone: session.status == .followUpDue ? .due : .neutral
                    )
                }
            }
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
            VStack(spacing: 12) {
                Text("We’ll remind you at week 4. You can keep using Xialla as usual.")
                    .font(BrandTheme.body(15))
                    .foregroundStyle(BrandTheme.graphite)
                SecondaryButton(title: "Reminder settings") {
                    session.path.append(.reminders)
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
        case .withdrawn:
            Text("You have withdrawn from the study.")
                .font(BrandTheme.body(16))
                .foregroundStyle(BrandTheme.graphite)
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
}
