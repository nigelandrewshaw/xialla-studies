import SwiftUI

struct ReminderSettingsView: View {
    @EnvironmentObject private var session: StudySession
    @State private var authorizationNote = "Not requested yet."

    var body: some View {
        ZStack {
            AtmosphereBackground()

            VStack(alignment: .leading, spacing: 24) {
                SectionIntro(
                    headline: "Reminders",
                    support: "This version schedules local notifications for the week‑4 follow-up only. Push notifications (APNs) can be added later."
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(authorizationNote)
                        .font(BrandTheme.body(15))
                        .foregroundStyle(BrandTheme.graphite)

                    if let due = session.enrollment?.followUpDueAt {
                        Text("Follow-up due \(due.formatted(date: .long, time: .omitted)).")
                            .font(BrandTheme.body(15, weight: .medium))
                            .foregroundStyle(BrandTheme.ink)
                    }

                    ForEach(session.snapshot.reminders) { reminder in
                        HStack {
                            Text(reminder.kind.rawValue)
                                .font(BrandTheme.body(14))
                            Spacer()
                            Text(reminder.fireAt.formatted(date: .abbreviated, time: .shortened))
                                .font(BrandTheme.body(13))
                                .foregroundStyle(BrandTheme.graphite)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Spacer()

                PrimaryButton(title: "Request notification permission") {
                    Task {
                        let scheduler = LocalReminderScheduler()
                        do {
                            let ok = try await scheduler.requestAuthorization()
                            authorizationNote = ok
                                ? "Notifications allowed."
                                : "Notifications denied — due date still shows on Home."
                        } catch {
                            authorizationNote = error.localizedDescription
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
    }
}
