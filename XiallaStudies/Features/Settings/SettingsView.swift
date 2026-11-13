import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var session: StudySession
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

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

                    Section("Investigator") {
                        Button {
                            dismiss()
                            session.path.append(.provider)
                        } label: {
                            HStack(spacing: 12) {
                                if let asset = StudyConfig.provider.photoAssetName {
                                    Image(asset)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 44, height: 44)
                                        .clipped()
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(StudyConfig.provider.displayName)
                                        .font(BrandTheme.body(15, weight: .semibold))
                                    Text(StudyConfig.provider.title)
                                        .font(BrandTheme.body(12))
                                        .foregroundStyle(BrandTheme.graphite)
                                }
                            }
                        }
                    }

                    Section("Participation") {
                        Toggle(
                            "Local reminders",
                            isOn: Binding(
                                get: { session.preferences.remindersEnabled },
                                set: { enabled in
                                    Task { await session.setRemindersEnabled(enabled) }
                                }
                            )
                        )
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

                    Section {
                        Button("Reset study progress", role: .destructive) {
                            confirmReset = true
                        }
                        Text("Clears LocalStudyStore on this device and returns to the splash so you can run consent from scratch.")
                            .font(BrandTheme.body(12))
                            .foregroundStyle(BrandTheme.graphite)
                    } header: {
                        Text("Demo")
                    }

                    Section("Jeff demo shortcuts") {
                        Button("Seed baseline complete + week 4 due") {
                            Task {
                                await session.demoSeedBaselineComplete()
                                dismiss()
                            }
                        }
                        if session.status == .baselineComplete || session.status == .followUpDue {
                            Button("Advance to week 4 (due now)") {
                                Task {
                                    await session.demoAdvanceToWeek4()
                                    dismiss()
                                }
                            }
                        }
                        if session.preferences.demoWeek4Advanced {
                            Text("Demo week‑4 advance is active (persisted).")
                                .font(BrandTheme.body(12))
                                .foregroundStyle(BrandTheme.graphite)
                        }
                    }

                    Section("About") {
                        Text("Xialla observational study companion. Progress is saved on this device between launches. Not a diagnostic or treatment tool.")
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
            .confirmationDialog(
                "Reset study progress?",
                isPresented: $confirmReset,
                titleVisibility: .visible
            ) {
                Button("Reset study progress", role: .destructive) {
                    Task {
                        await session.resetLocalDataForDebug()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes consent, surveys, and preferences stored locally, then restarts from splash.")
            }
        }
    }
}
