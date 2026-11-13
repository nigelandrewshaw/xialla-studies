import SwiftUI

#if canImport(ResearchKit) && canImport(ResearchKitUI)
import ResearchKit
import ResearchKitUI
import UIKit

struct ResearchKitSurveyPresenter: UIViewControllerRepresentable {
    let timepoint: SurveyTimepoint
    var onFinish: (_ result: SurveyTaskOutcome) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> ORKTaskViewController {
        let task = ResearchKitTaskFactory.makeSurveyTask(timepoint: timepoint)
        // Linked ResearchKit Swift overlay: init(task:taskRun:) (taskRunUUID was renamed).
        let vc = ORKTaskViewController(task: task, taskRun: nil)
        vc.delegate = context.coordinator
        vc.view.tintColor = UIColor(BrandTheme.tan)
        return vc
    }

    func updateUIViewController(_ uiViewController: ORKTaskViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(timepoint: timepoint, onFinish: onFinish, onCancel: onCancel)
    }

    final class Coordinator: NSObject, ORKTaskViewControllerDelegate {
        let timepoint: SurveyTimepoint
        let onFinish: (SurveyTaskOutcome) -> Void
        let onCancel: () -> Void

        init(
            timepoint: SurveyTimepoint,
            onFinish: @escaping (SurveyTaskOutcome) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.timepoint = timepoint
            self.onFinish = onFinish
            self.onCancel = onCancel
        }

        func taskViewController(
            _ taskViewController: ORKTaskViewController,
            didFinishWith reason: ORKTaskFinishReason,
            error: Error?
        ) {
            taskViewController.dismiss(animated: true) {
                if reason == .completed {
                    let outcome = SurveyResultParser.parse(
                        taskResult: taskViewController.result,
                        timepoint: self.timepoint
                    )
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
    var onFinish: (_ result: SurveyTaskOutcome) -> Void
    var onCancel: () -> Void

    var body: some View {
        // Branded custom IIEF-5 + companion surveys when RK is not linked.
        BrandedSurveyFallbackView(timepoint: timepoint, onFinish: onFinish, onCancel: onCancel)
    }
}

#endif
