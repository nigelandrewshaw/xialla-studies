import SwiftUI

/// Branded IIEF-5 + companion surveys when ResearchKit is not linked.
/// IIEF-5 items use **sliders 1–5 defaulting to 3** with official instrument wording.
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

    private let historyOptions: [(value: String, label: String)] = [
        ("yes", "Yes"),
        ("no", "No"),
        ("na", "Prefer not to say")
    ]

    private let aeOptions: [(value: String, label: String)] = [
        ("no", "No"),
        ("yes", "Yes")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground()

                Group {
                    switch page {
                    case .iief5:
                        iief5Page
                    case .companions:
                        companionsPage
                    case .done:
                        donePage
                    }
                }
                .padding(.horizontal, BrandTheme.contentInset)
                .padding(.vertical, 16)
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

    /// Full-page scroll so every IIEF-5 item and Continue stay reachable on short devices.
    private var iief5Page: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                SectionIntro(
                    headline: "IIEF-5",
                    support: "\(IIEF5Scoring.recallPeriodInstruction) Please rate each item from 1 to 5. Each slider starts at 3."
                )

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(IIEF5Scoring.items.enumerated()), id: \.offset) { index, item in
                        questionCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(index + 1). \(item.prompt)")
                                    .font(BrandTheme.body(14, weight: .medium))
                                    .foregroundStyle(BrandTheme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                HStack(alignment: .center, spacing: 8) {
                                    Text(item.lowLabel)
                                        .font(BrandTheme.body(11))
                                        .foregroundStyle(BrandTheme.graphite)
                                        .frame(maxWidth: 72, alignment: .leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Slider(value: $answers[index], in: 1...5, step: 1)
                                        .tint(BrandTheme.tan)
                                    Text(item.highLabel)
                                        .font(BrandTheme.body(11))
                                        .foregroundStyle(BrandTheme.graphite)
                                        .frame(maxWidth: 72, alignment: .trailing)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Text("Selected: \(Int(answers[index]))")
                                    .font(BrandTheme.body(13, weight: .semibold))
                                    .foregroundStyle(BrandTheme.ink)
                            }
                        }
                    }
                }

                PrimaryButton(title: "Continue") {
                    page = .companions
                }
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var companionsPage: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 18) {
                SectionIntro(
                    headline: "Additional questions",
                    support: timepoint == .baseline
                        ? "Please answer these history, usability, comfort, satisfaction, and adverse-event questions."
                        : "Please answer these usability, comfort, satisfaction, and adverse-event questions."
                )

                if timepoint == .baseline {
                    questionCard {
                        pickerRow(
                            "Have you used other treatments for erectile dysfunction before starting this study?",
                            selection: $historyPriorED,
                            options: historyOptions
                        )
                    }
                }

                questionCard {
                    sliderRow(
                        "Thinking about your experience so far, how easy was Xialla to use?",
                        value: $usability,
                        low: "Very difficult",
                        high: "Very easy"
                    )
                }
                questionCard {
                    sliderRow(
                        "How comfortable was Xialla to wear during use?",
                        value: $comfort,
                        low: "Very uncomfortable",
                        high: "Very comfortable"
                    )
                }
                questionCard {
                    sliderRow(
                        "Overall, how satisfied are you with Xialla?",
                        value: $satisfaction,
                        low: "Very dissatisfied",
                        high: "Very satisfied"
                    )
                }
                questionCard {
                    VStack(alignment: .leading, spacing: 10) {
                        pickerRow(
                            "Did you experience any adverse events or problems that you think may be related to using Xialla?",
                            selection: $aeAny,
                            options: aeOptions
                        )
                        if aeAny == "yes" {
                            Text("If you answered yes, please briefly describe what happened.")
                                .font(BrandTheme.body(15, weight: .semibold))
                                .fixedSize(horizontal: false, vertical: true)
                            TextField("Please describe what happened", text: $aeDetail, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 4).stroke(BrandTheme.mist))
                        }
                    }
                }
                questionCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Please share any additional comments for the study team. This is optional.")
                            .font(BrandTheme.body(15, weight: .semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        TextField("Optional comments for the study team", text: $freeText, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 4).stroke(BrandTheme.mist))
                    }
                }

                PrimaryButton(title: "Save responses") {
                    page = .done
                }
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var donePage: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                let ints = answers.map { Int($0) }
                let total = IIEF5Scoring.total(answers: ints) ?? 0
                let band = IIEF5Scoring.band(for: total)
                SectionIntro(
                    headline: "Responses saved locally",
                    support: "Your IIEF-5 total is \(total) (\(IIEF5Scoring.displayName(for: band))). Your progress will persist if you quit the app."
                )
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
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Interaction card for each survey control — keeps questions readable inside the scroll stack.
    private func questionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
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

    private func sliderRow(_ title: String, value: Binding<Double>, low: String, high: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(BrandTheme.body(15, weight: .semibold))
            HStack {
                Text(low).font(BrandTheme.body(12)).foregroundStyle(BrandTheme.graphite)
                Slider(value: value, in: 1...5, step: 1).tint(BrandTheme.tan)
                Text(high).font(BrandTheme.body(12)).foregroundStyle(BrandTheme.graphite)
            }
            Text("Selected: \(Int(value.wrappedValue))")
                .font(BrandTheme.body(13, weight: .medium))
                .foregroundStyle(BrandTheme.ink)
        }
    }

    private func pickerRow(
        _ title: String,
        selection: Binding<String>,
        options: [(value: String, label: String)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(BrandTheme.body(15, weight: .semibold))
            Picker(title, selection: selection) {
                ForEach(options, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
