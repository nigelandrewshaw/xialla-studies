import Foundation
import SwiftUI

/// In-memory + local study coordinator for the scaffold.
@MainActor
final class StudySession: ObservableObject {
    @Published private(set) var snapshot: StudySnapshot = .empty
    @Published var path: [AppRoute] = []
    @Published var showSettings = false
    @Published var isLoading = true
    @Published var lastError: String?

    private let store: any StudyStore
    private let api: any StudyAPIClient
    private let reminders: any ReminderScheduling

    init(
        store: any StudyStore = LocalStudyStore(),
        api: any StudyAPIClient = StubStudyAPIClient(),
        reminders: any ReminderScheduling = LocalReminderScheduler()
    ) {
        self.store = store
        self.api = api
        self.reminders = reminders
    }

    var enrollment: StudyEnrollment? { snapshot.enrollment }
    var status: EnrollmentStatus { snapshot.enrollment?.status ?? .notStarted }

    func bootstrap() async {
        isLoading = true
        defer { isLoading = false }
        do {
            snapshot = try await store.loadSnapshot()
            refreshDerivedStatus()
        } catch {
            lastError = error.localizedDescription
            snapshot = .empty
        }
    }

    func ensureParticipant() async {
        if snapshot.participant != nil { return }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        let participant = ParticipantProfile(
            id: UUID(),
            createdAt: Date(),
            localeIdentifier: Locale.current.identifier,
            appVersion: version,
            xiallaCustomerId: nil,
            meta: .makeNow()
        )
        snapshot.participant = participant
        await persist()
    }

    func beginEligibility() {
        path.append(.eligibility)
    }

    func selectProspectiveArm() async {
        await ensureParticipant()
        guard let participant = snapshot.participant else { return }
        let enrollment = StudyEnrollment(
            id: UUID(),
            participantId: participant.id,
            arm: .prospective,
            status: .eligible,
            enrolledAt: Date(),
            consentedAt: nil,
            consentVersion: nil,
            baselineCompletedAt: nil,
            followUpDueAt: nil,
            completedAt: nil,
            withdrawnAt: nil,
            meta: .makeNow()
        )
        snapshot.enrollment = enrollment
        snapshot.kit = KitFulfillmentStub(
            id: UUID(),
            enrollmentId: enrollment.id,
            status: .pendingDecision,
            notes: "Fulfillment timing TBD with Jeff — stub only.",
            meta: .makeNow()
        )
        await persist()
        path.append(.consent)
    }

    func completeConsent(comprehensionPassed: Bool, signatureBlobRef: String?) async {
        guard var enrollment = snapshot.enrollment else { return }
        let consent = ConsentRecord(
            id: UUID(),
            enrollmentId: enrollment.id,
            documentVersion: StudyConfig.consentDocumentVersion,
            signedAt: Date(),
            signatureBlobRef: signatureBlobRef,
            comprehensionPassed: comprehensionPassed,
            meta: .makeNow()
        )
        snapshot.consent = consent
        enrollment.status = .consented
        enrollment.consentedAt = consent.signedAt
        enrollment.consentVersion = consent.documentVersion
        snapshot.enrollment = enrollment
        await persist()

        do {
            try await api.submitConsent(consent)
        } catch {
            // Offline-first: keep local; surface later for sync.
            lastError = error.localizedDescription
        }

        path.append(.baselineSurveys)
    }

    func completeBaselineSurveys() async {
        guard var enrollment = snapshot.enrollment else { return }
        let now = Date()
        let instruments: [InstrumentCode] = [
            .iief5, .baselineHistory, .usability, .comfort, .satisfaction, .adverseEvents, .freeText
        ]

        for instrument in instruments {
            let admin = SurveyAdministration(
                id: UUID(),
                enrollmentId: enrollment.id,
                instrument: instrument,
                timepoint: .baseline,
                status: .completed,
                startedAt: now,
                completedAt: now,
                responses: stubResponses(for: instrument),
                scoreTotal: instrument == .iief5 ? 15 : nil,
                scoreBand: instrument == .iief5 ? "mild-to-moderate (stub)" : nil,
                meta: .makeNow()
            )
            snapshot.surveys.append(admin)
            do {
                try await api.submitSurvey(admin)
            } catch {
                lastError = error.localizedDescription
            }
        }

        enrollment.baselineCompletedAt = now
        enrollment.followUpDueAt = Calendar.current.date(
            byAdding: .day,
            value: StudyConfig.primaryFollowUpWeek * 7,
            to: now
        )
        enrollment.status = .baselineComplete
        snapshot.enrollment = enrollment

        do {
            _ = try await reminders.requestAuthorization()
            let schedules = try await reminders.scheduleWeek4FollowUp(
                enrollmentId: enrollment.id,
                baselineCompletedAt: now
            )
            snapshot.reminders.append(contentsOf: schedules)
        } catch {
            lastError = error.localizedDescription
        }

        await persist()
        path = []
    }

    func startWeek4FollowUp() {
        path.append(.week4FollowUp)
    }

    func completeWeek4FollowUp() async {
        guard var enrollment = snapshot.enrollment else { return }
        let now = Date()
        let instruments: [InstrumentCode] = [
            .iief5, .usability, .comfort, .satisfaction, .adverseEvents, .freeText
        ]
        for instrument in instruments {
            let admin = SurveyAdministration(
                id: UUID(),
                enrollmentId: enrollment.id,
                instrument: instrument,
                timepoint: .week4,
                status: .completed,
                startedAt: now,
                completedAt: now,
                responses: stubResponses(for: instrument),
                scoreTotal: instrument == .iief5 ? 18 : nil,
                scoreBand: instrument == .iief5 ? "mild (stub)" : nil,
                meta: .makeNow()
            )
            snapshot.surveys.append(admin)
        }
        enrollment.status = .completed
        enrollment.completedAt = now
        snapshot.enrollment = enrollment
        do {
            try await reminders.cancelReminders(enrollmentId: enrollment.id)
        } catch {
            lastError = error.localizedDescription
        }
        await persist()
        path = []
    }

    func withdraw() async {
        guard var enrollment = snapshot.enrollment else { return }
        enrollment.status = .withdrawn
        enrollment.withdrawnAt = Date()
        snapshot.enrollment = enrollment
        do {
            try await reminders.cancelReminders(enrollmentId: enrollment.id)
            try await api.withdraw(enrollmentId: enrollment.id, reason: nil)
        } catch {
            lastError = error.localizedDescription
        }
        await persist()
        path = []
        showSettings = false
    }

    func resetLocalDataForDebug() async {
        snapshot = .empty
        path = []
        await persist()
    }

    private func refreshDerivedStatus() {
        guard var enrollment = snapshot.enrollment else { return }
        if enrollment.status == .baselineComplete,
           let due = enrollment.followUpDueAt,
           due <= Date() {
            enrollment.status = .followUpDue
            snapshot.enrollment = enrollment
        }
    }

    private func persist() async {
        do {
            try await store.saveSnapshot(snapshot)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func stubResponses(for instrument: InstrumentCode) -> [SurveyResponseItem] {
        [
            SurveyResponseItem(
                id: UUID(),
                itemCode: "\(instrument.rawValue).stub",
                value: "stub",
                answeredAt: Date()
            )
        ]
    }
}

enum AppRoute: Hashable {
    case eligibility
    case consent
    case baselineSurveys
    case week4FollowUp
    case reminders
    case kitStub
}
