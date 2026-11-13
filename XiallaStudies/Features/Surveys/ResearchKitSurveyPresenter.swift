import SwiftUI

#if canImport(ResearchKit) && canImport(ResearchKitUI)
import ResearchKit
import ResearchKitUI

struct ResearchKitSurveyPresenter: UIViewControllerRepresentable {
    let timepoint: SurveyTimepoint
    var onFinish: () -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> ORKTaskViewController {
        let task = ResearchKitTaskFactory.makeSurveyTask(timepoint: timepoint)
        let vc = ORKTaskViewController(task: task, taskRun: nil)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: ORKTaskViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish, onCancel: onCancel)
    }

    final class Coordinator: NSObject, ORKTaskViewControllerDelegate {
        let onFinish: () -> Void
        let onCancel: () -> Void

        init(onFinish: @escaping () -> Void, onCancel: @escaping () -> Void) {
            self.onFinish = onFinish
            self.onCancel = onCancel
        }

        func taskViewController(
            _ taskViewController: ORKTaskViewController,
            didFinishWith reason: ORKTaskViewControllerFinishReason,
            error: Error?
        ) {
            taskViewController.dismiss(animated: true) {
                if reason == .completed {
                    self.onFinish()
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
    var onFinish: () -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("ResearchKit survey unavailable")
                    .font(BrandTheme.display(24, weight: .medium))
                Text("Link ResearchKit to present \(timepoint.displayName) as an ORKOrderedTask. Stub completion is available from the previous screen.")
                    .font(BrandTheme.body(15))
                    .foregroundStyle(BrandTheme.graphite)
                Spacer()
                PrimaryButton(title: "Mark complete (stub)") {
                    onFinish()
                }
                SecondaryButton(title: "Cancel", action: onCancel)
            }
            .padding(24)
        }
    }
}

#endif
