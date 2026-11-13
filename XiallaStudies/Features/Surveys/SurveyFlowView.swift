import SwiftUI

struct SurveyFlowView: View {
    @EnvironmentObject private var session: StudySession
    let timepoint: SurveyTimepoint

    @State private var activeInstrument: InstrumentCode?
    @State private var scoreSummary: String?
    @State private var isSavingInstrument = false

    private var instruments: [InstrumentCode] { timepoint.instruments }

    private var allComplete: Bool {
        instruments.allSatisfy { isComplete($0) }
    }

    var body: some View {
        ZStack {
            AtmosphereBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    SectionIntro(
                        headline: timepoint.displayName,
                        support: timepoint == .baseline
                            ? "Tap any questionnaire to open it. You can complete IIEF-5, history, and experience items in any order. Progress is saved on this device."
                            : "Tap any week‑4 questionnaire to open it in any order. IIEF-5 uses 1–5 sliders that start at 3. Progress is saved on this device."
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(instruments) { instrument in
                            Button {
                                activeInstrument = instrument
                            } label: {
                                HStack(spacing: 12) {
                                    Text(instrument.displayName)
                                        .font(BrandTheme.body(16, weight: .medium))
                                        .foregroundStyle(BrandTheme.ink)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 8)
                                    StatusChip(
                                        text: isComplete(instrument) ? "Done" : "Pending",
                                        tone: isComplete(instrument) ? .done : .neutral
                                    )
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(BrandTheme.graphite)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(BrandTheme.canvas)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(BrandTheme.mist, lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint(
                                isComplete(instrument)
                                    ? "Opens \(instrument.displayName). Currently marked Done; you can retake it."
                                    : "Opens \(instrument.displayName). Currently Pending."
                            )
                        }
                    }

                    if let scoreSummary {
                        Text(scoreSummary)
                            .font(BrandTheme.body(15, weight: .semibold))
                            .foregroundStyle(BrandTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if allComplete {
                        PrimaryButton(title: "Back to home") {
                            session.path = []
                        }
                    } else {
                        Text("\(completedCount) of \(instruments.count) complete — open any Pending row when ready.")
                            .font(BrandTheme.body(13))
                            .foregroundStyle(BrandTheme.graphite)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, BrandTheme.contentInset)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshSummary() }
        .onChange(of: session.snapshot.surveys) { _, _ in
            refreshSummary()
        }
        .sheet(item: $activeInstrument) { instrument in
            InstrumentSurveyView(
                timepoint: timepoint,
                instrument: instrument,
                existing: session.completedSurvey(timepoint: timepoint, instrument: instrument)
            ) { outcome in
                Task { @MainActor in
                    isSavingInstrument = true
                    await session.applySurveyOutcome(outcome, timepoint: timepoint)
                    refreshSummary()
                    isSavingInstrument = false
                    activeInstrument = nil
                }
            } onCancel: {
                activeInstrument = nil
            }
            .interactiveDismissDisabled(isSavingInstrument)
        }
    }

    private var completedCount: Int {
        instruments.filter { isComplete($0) }.count
    }

    private func isComplete(_ instrument: InstrumentCode) -> Bool {
        session.snapshot.surveys.contains {
            $0.timepoint == timepoint && $0.instrument == instrument && $0.status == .completed
        }
    }

    private func refreshSummary() {
        if let iief = session.snapshot.surveys.last(where: {
            $0.timepoint == timepoint && $0.instrument == .iief5 && $0.status == .completed
        }), let total = iief.scoreTotal {
            scoreSummary = "IIEF-5 \(total)" + (iief.scoreBand.map { " (\($0))" } ?? "")
        } else {
            scoreSummary = nil
        }
    }
}
