import Foundation
import UserNotifications

/// Schedules local notifications for the week-4 follow-up. Push / APNs comes later.
protocol ReminderScheduling: Sendable {
    func requestAuthorization() async throws -> Bool
    func scheduleWeek4FollowUp(enrollmentId: UUID, baselineCompletedAt: Date) async throws -> [ReminderSchedule]
    func cancelReminders(enrollmentId: UUID) async throws
}

actor LocalReminderScheduler: ReminderScheduling {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleWeek4FollowUp(enrollmentId: UUID, baselineCompletedAt: Date) async throws -> [ReminderSchedule] {
        let calendar = Calendar.current
        guard let due = calendar.date(byAdding: .day, value: StudyConfig.primaryFollowUpWeek * 7, to: baselineCompletedAt) else {
            return []
        }

        var schedules: [ReminderSchedule] = []

        for lead in StudyConfig.reminderLeadDays {
            guard let fireAt = calendar.date(byAdding: .day, value: -lead, to: due) else { continue }
            if fireAt <= Date() { continue }

            let id = UUID()
            let content = UNMutableNotificationContent()
            content.title = "Xialla Studies"
            content.body = lead == 0
                ? "Your week‑4 follow-up is ready."
                : "Your week‑4 follow-up is in \(lead) day\(lead == 1 ? "" : "s")."
            content.sound = .default
            content.userInfo = [
                "enrollmentId": enrollmentId.uuidString,
                "kind": ReminderKind.week4FollowUp.rawValue,
                "study_code": StudyConfig.studyCode,
                "site_code": StudyConfig.siteCode
            ]

            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireAt)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: "xialla.week4.\(enrollmentId.uuidString).lead\(lead)",
                content: content,
                trigger: trigger
            )
            try await center.add(request)

            schedules.append(
                ReminderSchedule(
                    id: id,
                    enrollmentId: enrollmentId,
                    kind: .week4FollowUp,
                    fireAt: fireAt,
                    channel: .local,
                    status: .scheduled,
                    meta: .makeNow()
                )
            )
        }

        return schedules
    }

    func cancelReminders(enrollmentId: UUID) async throws {
        let ids = StudyConfig.reminderLeadDays.map {
            "xialla.week4.\(enrollmentId.uuidString).lead\($0)"
        }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}

/// No-op scheduler for unit tests / previews.
actor NoopReminderScheduler: ReminderScheduling {
    func requestAuthorization() async throws -> Bool { false }
    func scheduleWeek4FollowUp(enrollmentId: UUID, baselineCompletedAt: Date) async throws -> [ReminderSchedule] { [] }
    func cancelReminders(enrollmentId: UUID) async throws {}
}
