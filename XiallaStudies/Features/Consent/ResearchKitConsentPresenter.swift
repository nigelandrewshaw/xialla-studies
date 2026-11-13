import SwiftUI

#if canImport(ResearchKit) && canImport(ResearchKitUI)
import ResearchKit
import ResearchKitUI

/// Presents an `ORKTaskViewController` for eConsent (info → comprehension → signature → PDF).
struct ResearchKitConsentPresenter: UIViewControllerRepresentable {
    var onFinish: (_ signatureRef: String?, _ pdfURL: URL?) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> ORKTaskViewController {
        let task = ResearchKitTaskFactory.makeConsentTask()
        let vc = ORKTaskViewController(task: task, taskRun: nil)
        vc.delegate = context.coordinator
        context.coordinator.document = ResearchKitTaskFactory.lastConsentDocument
        return vc
    }

    func updateUIViewController(_ uiViewController: ORKTaskViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish, onCancel: onCancel)
    }

    final class Coordinator: NSObject, ORKTaskViewControllerDelegate {
        let onFinish: (_ signatureRef: String?, _ pdfURL: URL?) -> Void
        let onCancel: () -> Void
        var document: ORKConsentDocument?

        init(
            onFinish: @escaping (_ signatureRef: String?, _ pdfURL: URL?) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onFinish = onFinish
            self.onCancel = onCancel
        }

        func taskViewController(
            _ taskViewController: ORKTaskViewController,
            didFinishWith reason: ORKTaskViewControllerFinishReason,
            error: Error?
        ) {
            if reason == .completed {
                let signatureRef = ConsentResultParser.signatureReference(
                    from: taskViewController.result
                )
                ConsentPDFExporter.export(document: document) { [weak self] url in
                    taskViewController.dismiss(animated: true) {
                        self?.onFinish(signatureRef, url)
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

/// Fallback when ResearchKit is not yet linked — branded SwiftUI consent still works.
struct ResearchKitConsentPresenter: View {
    var onFinish: (_ signatureRef: String?, _ pdfURL: URL?) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("ResearchKit not linked")
                    .font(BrandTheme.display(24, weight: .medium))
                Text("Add ResearchKit + ResearchKitUI to the Xcode target (see README). Until then, use the in-app consent stubs.")
                    .font(BrandTheme.body(15))
                    .foregroundStyle(BrandTheme.graphite)
                Spacer()
                PrimaryButton(title: "Continue without ResearchKit UI") {
                    onFinish("local-stub:rk-unavailable", nil)
                }
                SecondaryButton(title: "Cancel") {
                    onCancel()
                }
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onCancel)
                }
            }
        }
    }
}

#endif
