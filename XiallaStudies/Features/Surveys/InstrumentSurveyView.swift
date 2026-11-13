import SwiftUI

/// Single-instrument survey sheet — any baseline/follow-up row can open anytime (no forced sequence).
struct InstrumentSurveyView: View {
    let timepoint: SurveyTimepoint
    let instrument: InstrumentCode
    var onFinish: (SurveyTaskOutcome) -> Void
    var onCancel: () -> Void

    @State private var iiefAnswers: [Double] = Array(repeating: 3, count: 5)
    @State private var likert: Double = 3
    @State private var historyPriorED = "no"
    @State private var historyNotes = ""
    @State private var aeAny = "no"
    @State private var aeDetail = ""
    @State private var freeText = ""

    private let yesNoNa: [(value: String, label: String)] = [
        ("yes", "Yes"),
        ("no", "No"),
        ("na", "Prefer not to say")
    ]
    private let yesNo: [(value: String, label: String)] = [
        ("no", "No"),
        ("yes", "Yes")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground()

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionIntro(
                            headline: instrument.displayName,
                            support: supportCopy
                        )

                        contentCard

                        PrimaryButton(title: "Save") {
                            onFinish(buildOutcome())
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, BrandTheme.contentInset)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
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

    @ViewBuilder
    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch instrument {
            case .iief5:
                ForEach(Array(IIEF5Scoring.items.enumerated()), id: \.offset) { index, item in
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
                            Slider(value: $iiefAnswers[index], in: 1...5, step: 1)
                                .tint(BrandTheme.tan)
                            Text(item.highLabel)
                                .font(BrandTheme.body(11))
                                .foregroundStyle(BrandTheme.graphite)
                                .frame(maxWidth: 72, alignment: .trailing)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Text("Selected: \(Int(iiefAnswers[index]))")
                            .font(BrandTheme.body(13, weight: .semibold))
                            .foregroundStyle(BrandTheme.ink)
                    }
                }
            case .baselineHistory:
                picker(
                    "Have you used other treatments for erectile dysfunction before starting this study?",
                    selection: $historyPriorED,
                    options: yesNoNa
                )
                Text("Is there anything else you would like the study team to know about your history before first use of Xialla?")
                    .font(BrandTheme.body(15, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)
                TextField("Optional notes", text: $historyNotes, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 4).stroke(BrandTheme.mist))
            case .usability:
                likertSlider(
                    "Thinking about your experience so far, how easy was Xialla to use?",
                    low: "Very difficult",
                    high: "Very easy"
                )
            case .comfort:
                likertSlider(
                    "How comfortable was Xialla to wear during use?",
                    low: "Very uncomfortable",
                    high: "Very comfortable"
                )
            case .satisfaction:
                likertSlider(
                    "Overall, how satisfied are you with Xialla?",
                    low: "Very dissatisfied",
                    high: "Very satisfied"
                )
            case .adverseEvents:
                picker(
                    "Did you experience any adverse events or problems that you think may be related to using Xialla?",
                    selection: $aeAny,
                    options: yesNo
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
            case .freeText:
                Text("Please share any additional comments for the study team. This is optional.")
                    .font(BrandTheme.body(15, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)
                TextField("Optional comments for the study team", text: $freeText, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 4).stroke(BrandTheme.mist))
            }
        }
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

    private var supportCopy: String {
        switch instrument {
        case .iief5:
            return "\(IIEF5Scoring.recallPeriodInstruction) Please rate each item from 1 to 5. Each slider starts at 3."
        case .baselineHistory:
            return "Brief history questions for this study site. You can open any questionnaire from the list in any order."
        case .usability, .comfort, .satisfaction:
            return "Rate this item from 1 to 5. The slider starts at 3."
        case .adverseEvents:
            return "Report any problems that may be related to Xialla use."
        case .freeText:
            return "Optional comments for the study team."
        }
    }

    private func likertSlider(_ title: String, low: String, high: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(BrandTheme.body(15, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Text(low).font(BrandTheme.body(12)).foregroundStyle(BrandTheme.graphite)
                Slider(value: $likert, in: 1...5, step: 1).tint(BrandTheme.tan)
                Text(high).font(BrandTheme.body(12)).foregroundStyle(BrandTheme.graphite)
            }
            Text("Selected: \(Int(likert))")
                .font(BrandTheme.body(13, weight: .medium))
                .foregroundStyle(BrandTheme.ink)
        }
    }

    private func picker(
        _ title: String,
        selection: Binding<String>,
        options: [(value: String, label: String)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(BrandTheme.body(15, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
            Picker(title, selection: selection) {
                ForEach(options, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func buildOutcome() -> SurveyTaskOutcome {
        switch instrument {
        case .iief5:
            return SurveyTaskOutcome.singleIIEF5(
                timepoint: timepoint,
                answers: iiefAnswers.map { Int($0) }
            )
        case .baselineHistory:
            let value = historyNotes.isEmpty ? historyPriorED : "\(historyPriorED)|\(historyNotes)"
            return SurveyTaskOutcome.singleNote(
                instrument: .baselineHistory,
                timepoint: timepoint,
                value: value
            )
        case .usability, .comfort, .satisfaction:
            return SurveyTaskOutcome.singleNote(
                instrument: instrument,
                timepoint: timepoint,
                value: String(Int(likert))
            )
        case .adverseEvents:
            return SurveyTaskOutcome.singleNote(
                instrument: .adverseEvents,
                timepoint: timepoint,
                value: aeAny == "yes" ? aeDetail : "none"
            )
        case .freeText:
            return SurveyTaskOutcome.singleNote(
                instrument: .freeText,
                timepoint: timepoint,
                value: freeText
            )
        }
    }
}
