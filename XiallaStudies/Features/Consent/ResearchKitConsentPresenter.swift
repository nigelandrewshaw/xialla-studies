import SwiftUI

#if canImport(ResearchKit) && canImport(ResearchKitUI)
import ResearchKit
import ResearchKitUI
import UIKit

/// Presents an `ORKTaskViewController` for eConsent (info → comprehension → signature → PDF).
struct ResearchKitConsentPresenter: UIViewControllerRepresentable {
    var onFinish: (_ signatureRef: String?, _ pdfURL: URL?, _ comprehensionPassed: Bool) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> ORKTaskViewController {
        let task = ResearchKitTaskFactory.makeConsentTask()
        // Linked ResearchKit Swift overlay: init(task:taskRun:) (taskRunUUID was renamed).
        let vc = ORKTaskViewController(task: task, taskRun: nil)
        vc.delegate = context.coordinator
        ResearchKitChrome.style(vc)
        context.coordinator.document = ResearchKitTaskFactory.lastConsentDocument
        return vc
    }

    func updateUIViewController(_ uiViewController: ORKTaskViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish, onCancel: onCancel)
    }

    final class Coordinator: NSObject, ORKTaskViewControllerDelegate {
        let onFinish: (_ signatureRef: String?, _ pdfURL: URL?, _ comprehensionPassed: Bool) -> Void
        let onCancel: () -> Void
        var document: ORKConsentDocument?

        init(
            onFinish: @escaping (_ signatureRef: String?, _ pdfURL: URL?, _ comprehensionPassed: Bool) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onFinish = onFinish
            self.onCancel = onCancel
        }

        func taskViewController(
            _ taskViewController: ORKTaskViewController,
            stepViewControllerWillAppear stepViewController: ORKStepViewController
        ) {
            // ORK labels reset fonts on appear; re-apply Fieldwork, square icons, scroll inset.
            DispatchQueue.main.async {
                ResearchKitChrome.polishStepView(stepViewController.view)
            }
        }

        func taskViewController(
            _ taskViewController: ORKTaskViewController,
            didFinishWith reason: ORKTaskFinishReason,
            error: Error?
        ) {
            if reason == .completed {
                let result = taskViewController.result
                let signatureRef = ConsentResultParser.signatureReference(from: result)
                let passed = ConsentResultParser.comprehensionPassed(from: result)
                ConsentPDFExporter.export(document: document) { [weak self] url in
                    taskViewController.dismiss(animated: true) {
                        self?.onFinish(signatureRef, url, passed)
                    }
                }
            } else {
                taskViewController.dismiss(animated: true) {
                    self.onCancel()
                }
            }
        }
    }
}

#else

/// Fallback when ResearchKit is not linked — branded SwiftUI consent still works.
struct ResearchKitConsentPresenter: View {
    var onFinish: (_ signatureRef: String?, _ pdfURL: URL?, _ comprehensionPassed: Bool) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("ResearchKit is not linked yet")
                    .font(BrandTheme.display(24, weight: .medium))
                Text("Run ./scripts/bootstrap-researchkit.sh on a Mac, then reopen XiallaStudies.xcodeproj. Until then, please use the in-app consent review on the previous screen.")
                    .font(BrandTheme.body(15))
                    .foregroundStyle(BrandTheme.graphite)
                Spacer()
                PrimaryButton(title: "Continue without ResearchKit UI") {
                    onFinish("local-stub:rk-unavailable", nil, true)
                }
                SecondaryButton(title: "Cancel") {
                    onCancel()
                }
            }
            .padding(24)
            .background(BrandTheme.canvas.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onCancel)
                }
            }
        }
    }
}

#endif
