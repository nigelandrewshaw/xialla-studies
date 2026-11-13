import SwiftUI
import UIKit

/// Single-instrument survey sheet — any baseline/follow-up row can open anytime (no forced sequence).
/// All content (including IIEF-5 × 5 + Save) lives in `KeyboardAvoidingFormScroll`.
struct InstrumentSurveyView: View {
    let timepoint: SurveyTimepoint
    let instrument: InstrumentCode
    /// Prior completed administration for this row (retake / restore after relaunch).
    var existing: SurveyAdministration? = nil
    var onFinish: (SurveyTaskOutcome) -> Void
    var onCancel: () -> Void

    @State private var iiefAnswers: [Double] = Array(repeating: 3, count: 5)
    @State private var likert: Double = 3
    @State private var historyPriorED = "no"
    @State private var historyNotes = ""
    @State private var aeAny = "no"
    @State private var aeDetail = ""
    @State private var freeText = ""
    @State private var didHydrate = false

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
                    .allowsHitTesting(false)

                KeyboardAvoidingFormScroll {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionIntro(
                            headline: instrument.displayName,
                            support: supportCopy
                        )

                        content

                        PrimaryButton(title: "Save") {
                            onFinish(buildOutcome())
                        }
                        .formPrimaryActionAnchor()
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                    }
                    .padding(.horizontal, BrandTheme.contentInset)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(timepoint.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
                    .font(BrandTheme.body(16, weight: .semibold))
                }
            }
            .onAppear { hydrateFromExistingIfNeeded() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch instrument {
        case .iief5:
            // One card per item so all 5 + Save scroll fully on short screens.
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
            }
        case .baselineHistory:
            questionCard {
                VStack(alignment: .leading, spacing: 14) {
                    picker(
                        "Have you used other treatments for erectile dysfunction before starting this study?",
                        selection: $historyPriorED,
                        options: yesNoNa
                    )
                    Text("Is there anything else you would like the study team to know about your history before first use of Xialla?")
                        .font(BrandTheme.body(15, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    formTextEditor(text: $historyNotes, placeholder: "Optional notes")
                }
            }
        case .usability:
            questionCard {
                likertSlider(
                    "Thinking about your experience so far, how easy was Xialla to use?",
                    low: "Very difficult",
                    high: "Very easy"
                )
            }
        case .comfort:
            questionCard {
                likertSlider(
                    "How comfortable was Xialla to wear during use?",
                    low: "Very uncomfortable",
                    high: "Very comfortable"
                )
            }
        case .satisfaction:
            questionCard {
                likertSlider(
                    "Overall, how satisfied are you with Xialla?",
                    low: "Very dissatisfied",
                    high: "Very satisfied"
                )
            }
        case .adverseEvents:
            questionCard {
                VStack(alignment: .leading, spacing: 14) {
                    picker(
                        "Did you experience any adverse events or problems that you think may be related to using Xialla?",
                        selection: $aeAny,
                        options: yesNo
                    )
                    if aeAny == "yes" {
                        Text("If you answered yes, please briefly describe what happened.")
                            .font(BrandTheme.body(15, weight: .semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        formTextEditor(text: $aeDetail, placeholder: "Please describe what happened")
                    }
                }
            }
        case .freeText:
            questionCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Please share any additional comments for the study team. This is optional.")
                        .font(BrandTheme.body(15, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    formTextEditor(text: $freeText, placeholder: "Optional comments for the study team")
                }
            }
        }
    }

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

    private func formTextEditor(text: Binding<String>, placeholder: String) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholder)
                    .font(BrandTheme.body(15))
                    .foregroundStyle(BrandTheme.graphite.opacity(0.55))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .allowsHitTesting(false)
            }
            TextEditor(text: text)
                .font(BrandTheme.body(15))
                .foregroundStyle(BrandTheme.ink)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
                .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(BrandTheme.mist, lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.92))
                )
        )
    }

    private var supportCopy: String {
        switch instrument {
        case .iief5:
            return "\(IIEF5Scoring.recallPeriodInstruction) Please rate each item from 1 to 5. Each slider starts at 3. Scroll to reach every question and Save."
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

    private func hydrateFromExistingIfNeeded() {
        guard !didHydrate, let existing, existing.status == .completed else {
            didHydrate = true
            return
        }
        didHydrate = true
        switch instrument {
        case .iief5:
            var restored = Array(repeating: 3.0, count: 5)
            for q in 1...5 {
                if let item = existing.responses.first(where: { $0.itemCode == "iief5.q\(q)" }),
                   let value = Double(item.value) {
                    restored[q - 1] = min(5, max(1, value))
                }
            }
            iiefAnswers = restored
        case .baselineHistory:
            let raw = existing.responses.first?.value ?? "no"
            let parts = raw.split(separator: "|", maxSplits: 1).map(String.init)
            historyPriorED = parts.first ?? "no"
            historyNotes = parts.count > 1 ? parts[1] : ""
        case .usability, .comfort, .satisfaction:
            if let value = existing.responses.first?.value, let number = Double(value) {
                likert = min(5, max(1, number))
            }
        case .adverseEvents:
            let value = existing.responses.first?.value ?? "none"
            if value == "none" || value.isEmpty {
                aeAny = "no"
                aeDetail = ""
            } else {
                aeAny = "yes"
                aeDetail = value
            }
        case .freeText:
            freeText = existing.responses.first?.value ?? ""
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
