import SwiftUI

/// Branded IIEF-5 + companion surveys when ResearchKit is not linked.
/// IIEF-5 items use **sliders 1–5 defaulting to 3**.
struct BrandedSurveyFallbackView: View {
    let timepoint: SurveyTimepoint
    var onFinish: (SurveyTaskOutcome) -> Void
    var onCancel: () -> Void

    @State private var answers: [Double] = Array(repeating: 3, count: 5)
    @State private var page: Page = .iief5
    @State private var historyPriorED = "no"
    @State private var usability: Double = 3
    @State private var comfort: Double = 3
    @State private var satisfaction: Double = 3
    @State private var aeAny = "no"
    @State private var aeDetail = ""
    @State private var freeText = ""

    enum Page {
        case iief5, companions, done
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground()

                VStack(alignment: .leading, spacing: 20) {
                    switch page {
                    case .iief5:
                        iief5Page
                    case .companions:
                        companionsPage
                    case .done:
                        donePage
                    }
                }
                .padding(24)
            }
            .navigationTitle(timepoint.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onCancel)
                }
            }
        }
    }

    private var iief5Page: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionIntro(
                headline: "IIEF-5",
                support: "Each item is a 1–5 slider starting at 3. Official wording pending license clearance."
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(0..<5, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(index + 1). \(IIEF5Scoring.placeholderPrompts[index])")
                                .font(BrandTheme.body(14, weight: .medium))
                                .foregroundStyle(BrandTheme.ink)
                            HStack {
                                Text("1")
                                    .font(BrandTheme.body(12))
                                    .foregroundStyle(BrandTheme.graphite)
                                Slider(value: $answers[index], in: 1...5, step: 1)
                                    .tint(BrandTheme.accent)
                                Text("5")
                                    .font(BrandTheme.body(12))
                                    .foregroundStyle(BrandTheme.graphite)
                            }
                            Text("Selected: \(Int(answers[index]))")
                                .font(BrandTheme.body(13, weight: .semibold))
                                .foregroundStyle(BrandTheme.accent)
                        }
                    }
                }
            }

            PrimaryButton(title: "Continue") {
                page = .companions
            }
        }
    }

    private var companionsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionIntro(
                    headline: "Additional questions",
                    support: timepoint == .baseline
                        ? "History, usability, comfort, satisfaction, and adverse events."
                        : "Usability, comfort, satisfaction, and adverse events."
                )

                if timepoint == .baseline {
                    pickerRow("Prior ED treatment?", selection: $historyPriorED, options: ["yes", "no", "na"])
                }

                sliderRow("Usability", value: $usability, low: "Hard", high: "Easy")
                sliderRow("Comfort", value: $comfort, low: "Low", high: "High")
                sliderRow("Satisfaction", value: $satisfaction, low: "Low", high: "High")
                pickerRow("Any adverse events?", selection: $aeAny, options: ["no", "yes"])
                if aeAny == "yes" {
                    TextField("Describe", text: $aeDetail, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 4).stroke(BrandTheme.mist))
                }
                TextField("Optional comments", text: $freeText, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 4).stroke(BrandTheme.mist))

                PrimaryButton(title: "Save responses") {
                    page = .done
                }
            }
        }
    }

    private var donePage: some View {
        VStack(alignment: .leading, spacing: 16) {
            let ints = answers.map { Int($0) }
            let total = IIEF5Scoring.total(answers: ints) ?? 0
            let band = IIEF5Scoring.band(for: total)
            SectionIntro(
                headline: "Saved locally",
                support: "IIEF-5 total \(total) (\(IIEF5Scoring.displayName(for: band))). Progress persists if you quit the app."
            )
            Spacer()
            PrimaryButton(title: "Done") {
                var notes: [InstrumentCode: String] = [
                    .usability: String(Int(usability)),
                    .comfort: String(Int(comfort)),
                    .satisfaction: String(Int(satisfaction)),
                    .adverseEvents: aeAny == "yes" ? aeDetail : "none",
                    .freeText: freeText
                ]
                if timepoint == .baseline {
                    notes[.baselineHistory] = historyPriorED
                }
                onFinish(
                    SurveyResultParser.fromBrandedIIEF5(
                        timepoint: timepoint,
                        answers: ints,
                        companionNotes: notes
                    )
                )
            }
        }
    }

    private func sliderRow(_ title: String, value: Binding<Double>, low: String, high: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(BrandTheme.body(15, weight: .semibold))
            HStack {
                Text(low).font(BrandTheme.body(12)).foregroundStyle(BrandTheme.graphite)
                Slider(value: value, in: 1...5, step: 1).tint(BrandTheme.accent)
                Text(high).font(BrandTheme.body(12)).foregroundStyle(BrandTheme.graphite)
            }
            Text("\(Int(value.wrappedValue))")
                .font(BrandTheme.body(13, weight: .medium))
                .foregroundStyle(BrandTheme.accent)
        }
    }

    private func pickerRow(_ title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(BrandTheme.body(15, weight: .semibold))
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }
}
