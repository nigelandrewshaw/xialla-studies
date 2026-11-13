import SwiftUI

struct SurveyFlowView: View {
    @EnvironmentObject private var session: StudySession
    let timepoint: SurveyTimepoint

    @State private var showResearchKit = false
    @State private var completedLocally = false

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
                        ? "Complete these before first use when possible. IIEF-5 wording is placeholder until licensed."
                        : "Week‑4 instruments. Additional 8/12-week timepoints can plug into the same structure later."
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

                Spacer()

                VStack(spacing: 12) {
                    SecondaryButton(title: "Open ResearchKit survey task") {
                        showResearchKit = true
                    }
                    PrimaryButton(title: completedLocally ? "Continue" : "Complete stubs & save") {
                        Task {
                            if !completedLocally {
                                if timepoint == .baseline {
                                    await session.completeBaselineSurveys()
                                } else if timepoint == .week4 {
                                    await session.completeWeek4FollowUp()
                                }
                                completedLocally = true
                            } else {
                                session.path = []
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showResearchKit) {
            ResearchKitSurveyPresenter(timepoint: timepoint) {
                showResearchKit = false
                Task {
                    if timepoint == .baseline {
                        await session.completeBaselineSurveys()
                    } else if timepoint == .week4 {
                        await session.completeWeek4FollowUp()
                    }
                    completedLocally = true
                }
            } onCancel: {
                showResearchKit = false
            }
        }
    }
}
