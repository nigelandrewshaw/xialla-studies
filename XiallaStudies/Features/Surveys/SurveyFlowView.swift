import SwiftUI

struct SurveyFlowView: View {
    @EnvironmentObject private var session: StudySession
    let timepoint: SurveyTimepoint

    @State private var showResearchKit = false
    @State private var completedLocally = false
    @State private var scoreSummary: String?

    private var instruments: [InstrumentCode] {
        switch timepoint {
        case .baseline:
            return [.iief5, .baselineHistory, .usability, .comfort, .satisfaction, .adverseEvents, .freeText]
        case .week4, .week8, .week12:
            return [.iief5, .usability, .comfort, .satisfaction, .adverseEvents, .freeText]
        }
    }

    var body: some View {
        ZStack {
            AtmosphereBackground()

            VStack(alignment: .leading, spacing: 24) {
                SectionIntro(
                    headline: timepoint.displayName,
                    support: timepoint == .baseline
                        ? "Please complete the IIEF-5 (1–5 sliders that start at 3), then the history and experience questions. Your answers are saved on this device."
                        : "Please complete the week‑4 follow-up questionnaires. The IIEF-5 uses 1–5 sliders that start at 3. Your answers are saved on this device."
                )

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(instruments) { instrument in
                        HStack {
                            Text(instrument.displayName)
                                .font(BrandTheme.body(16, weight: .medium))
                                .foregroundStyle(BrandTheme.ink)
                            Spacer()
                            StatusChip(
                                text: completedLocally ? "Done" : "Pending",
                                tone: completedLocally ? .done : .neutral
                            )
                        }
                        .padding(.vertical, 6)
                    }
                }

                if let scoreSummary {
                    Text(scoreSummary)
                        .font(BrandTheme.body(15, weight: .semibold))
                        .foregroundStyle(BrandTheme.ink)
                }

                Spacer()

                VStack(spacing: 12) {
                    if !completedLocally {
                        PrimaryButton(title: "Start questionnaires") {
                            showResearchKit = true
                        }
                    } else {
                        PrimaryButton(title: "Back to home") {
                            session.path = []
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Reflect already-persisted administrations after relaunch.
            let existing = session.snapshot.surveys.filter { $0.timepoint == timepoint && $0.status == .completed }
            if !existing.isEmpty {
                completedLocally = true
                if let iief = existing.first(where: { $0.instrument == .iief5 }),
                   let total = iief.scoreTotal {
                    scoreSummary = "IIEF-5 \(total)" + (iief.scoreBand.map { " (\($0))" } ?? "")
                }
            }
        }
        .sheet(isPresented: $showResearchKit) {
            ResearchKitSurveyPresenter(timepoint: timepoint) { outcome in
                showResearchKit = false
                Task {
                    await session.applySurveyOutcome(outcome, timepoint: timepoint)
                    completedLocally = true
                    if let total = outcome.iief5Total, let band = outcome.iief5Band {
                        scoreSummary = "IIEF-5 \(total) (\(IIEF5Scoring.displayName(for: band)))"
                    }
                }
            } onCancel: {
                showResearchKit = false
            }
        }
    }
}
