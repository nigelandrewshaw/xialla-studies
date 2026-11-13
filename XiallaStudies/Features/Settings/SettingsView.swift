import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var session: StudySession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground()

                List {
                    Section("Study") {
                        LabeledContent("Study code", value: StudyConfig.studyCode)
                        LabeledContent("Site code", value: StudyConfig.siteCode)
                        LabeledContent("Consent version", value: StudyConfig.consentDocumentVersion)
                        LabeledContent(
                            "Bundle ID (suggested)",
                            value: StudyConfig.suggestedBundleIdentifier
                        )
                    }

                    Section("Participation") {
                        Button("Reminder settings") {
                            dismiss()
                            session.path.append(.reminders)
                        }
                        Button("Kit fulfillment (stub)") {
                            dismiss()
                            session.path.append(.kitStub)
                        }
                        if session.enrollment != nil, session.status != .withdrawn {
                            Button("Withdraw from study", role: .destructive) {
                                Task { await session.withdraw() }
                            }
                        }
                    }

                    Section("Debug") {
                        Button("Reset local study data", role: .destructive) {
                            Task { await session.resetLocalDataForDebug() }
                        }
                    }

                    Section("About") {
                        Text("Xialla observational study companion. Not a diagnostic or treatment tool.")
                            .font(BrandTheme.body(14))
                            .foregroundStyle(BrandTheme.graphite)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
