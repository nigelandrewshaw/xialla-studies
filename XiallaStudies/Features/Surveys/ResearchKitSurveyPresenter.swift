import SwiftUI

#if canImport(ResearchKit) && canImport(ResearchKitUI)
import ResearchKit
import ResearchKitUI
import UIKit

struct ResearchKitSurveyPresenter: UIViewControllerRepresentable {
    let timepoint: SurveyTimepoint
    /// When set, presents only that instrument (list rows open independently).
    var instrument: InstrumentCode? = nil
    var onFinish: (_ result: SurveyTaskOutcome) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> ORKTaskViewController {
        let task: ORKOrderedTask
        if let instrument {
            task = ResearchKitTaskFactory.makeInstrumentTask(timepoint: timepoint, instrument: instrument)
        } else {
            task = ResearchKitTaskFactory.makeSurveyTask(timepoint: timepoint)
        }
        // Linked ResearchKit Swift overlay: init(task:taskRun:) (taskRunUUID was renamed).
        let vc = ORKTaskViewController(task: task, taskRun: nil)
        vc.delegate = context.coordinator
        ResearchKitChrome.style(vc)
        return vc
    }

    func updateUIViewController(_ uiViewController: ORKTaskViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(
            timepoint: timepoint,
            instrument: instrument,
            onFinish: onFinish,
            onCancel: onCancel
        )
    }

    final class Coordinator: NSObject, ORKTaskViewControllerDelegate {
        let timepoint: SurveyTimepoint
        let instrument: InstrumentCode?
        let onFinish: (SurveyTaskOutcome) -> Void
        let onCancel: () -> Void

        init(
            timepoint: SurveyTimepoint,
            instrument: InstrumentCode?,
            onFinish: @escaping (SurveyTaskOutcome) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.timepoint = timepoint
            self.instrument = instrument
            self.onFinish = onFinish
            self.onCancel = onCancel
        }

        func taskViewController(
            _ taskViewController: ORKTaskViewController,
            stepViewControllerWillAppear stepViewController: ORKStepViewController
        ) {
            DispatchQueue.main.async {
                ResearchKitChrome.polishStepView(stepViewController.view)
            }
        }

        func taskViewController(
            _ taskViewController: ORKTaskViewController,
            didFinishWith reason: ORKTaskFinishReason,
            error: Error?
        ) {
            taskViewController.dismiss(animated: true) {
                if reason == .completed {
                    let outcome: SurveyTaskOutcome
                    if let instrument = self.instrument {
                        outcome = SurveyResultParser.parseInstrument(
                            taskResult: taskViewController.result,
                            timepoint: self.timepoint,
                            instrument: instrument
                        )
                    } else {
                        outcome = SurveyResultParser.parse(
                            taskResult: taskViewController.result,
                            timepoint: self.timepoint
                        )
                    }
                    self.onFinish(outcome)
                } else {
                    self.onCancel()
                }
            }
        }
    }
}

#else

struct ResearchKitSurveyPresenter: View {
    let timepoint: SurveyTimepoint
    var instrument: InstrumentCode? = nil
    var onFinish: (_ result: SurveyTaskOutcome) -> Void
    var onCancel: () -> Void

    var body: some View {
        if let instrument {
            InstrumentSurveyView(
                timepoint: timepoint,
                instrument: instrument,
                onFinish: onFinish,
                onCancel: onCancel
            )
        } else {
            // Legacy full-battery branded flow when no row instrument is specified.
            BrandedSurveyFallbackView(timepoint: timepoint, onFinish: onFinish, onCancel: onCancel)
        }
    }
}

#endif
