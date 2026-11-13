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
                        ? "IIEF-5 uses 1–5 sliders (default 3), then history and experience questions. Saved on-device."
                        : "Week‑4 instruments. IIEF-5 sliders default to 3."
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
                        .foregroundStyle(BrandTheme.teal)
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
