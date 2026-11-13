import Foundation
import SwiftUI

/// In-memory + local study coordinator. Every mutation persists via `LocalStudyStore`
/// so Jeff can quit mid-demo and reopen without losing progress.
@MainActor
final class StudySession: ObservableObject {
    @Published private(set) var snapshot: StudySnapshot = .empty
    @Published var path: [AppRoute] = [] {
        didSet { Task { await persistResumeRoute() } }
    }
    @Published var showSettings = false
    /// Replays the brand splash from Home (does not clear study progress).
    @Published var showBrandSplash = false
    @Published var isLoading = true
    @Published var lastError: String?
    @Published var lastIIEF5Summary: String?

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
    var preferences: StudyPreferences { snapshot.preferences }
    var hasSeenSplash: Bool { snapshot.preferences.hasSeenSplash }

    // MARK: - Lifecycle

    func bootstrap() async {
        isLoading = true
        defer { isLoading = false }
        do {
            snapshot = try await store.loadSnapshot()
            refreshDerivedStatus()
            if let route = snapshot.preferences.resumeRoute {
                path = [route]
            }
        } catch {
            lastError = error.localizedDescription
            snapshot = .empty
        }
    }

    func markSplashSeen() async {
        snapshot.preferences.hasSeenSplash = true
        await persist()
    }

    /// Home hero wordmark — show splash again without wiping enrollment / surveys.
    func presentBrandSplash() {
        showSettings = false
        path = []
        showBrandSplash = true
    }

    func dismissBrandSplash() {
        showBrandSplash = false
    }

    // MARK: - Flow

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

    func completeConsent(
        comprehensionPassed: Bool,
        signatureBlobRef: String?,
        pdfURL: URL? = nil,
        navigateToBaseline: Bool = true
    ) async {
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
        snapshot.consentPDFPath = pdfURL?.path
        enrollment.status = .consented
        enrollment.consentedAt = consent.signedAt
        enrollment.consentVersion = consent.documentVersion
        snapshot.enrollment = enrollment
        await persist()

        do {
            try await api.submitConsent(consent)
        } catch {
            lastError = error.localizedDescription
        }

        if navigateToBaseline {
            path.append(.baselineSurveys)
        }
    }

    func applySurveyOutcome(_ outcome: SurveyTaskOutcome, timepoint: SurveyTimepoint) async {
        // Ensure we always have an enrollment to attach administrations to.
        if snapshot.enrollment == nil {
            await ensureParticipant()
            await selectProspectiveArmIfNeededForSurveySave()
        }
        guard var enrollment = snapshot.enrollment else {
            lastError = "Could not save survey — no enrollment on this device."
            return
        }
        let enrollmentId = enrollment.id

        // Copy-on-write so @Published always emits and LocalStudyStore gets the merged surveys.
        var next = snapshot
        let now = Date()

        // Merge per instrument so rows can be completed in any order (re-take replaces that instrument only).
        for var admin in outcome.administrations {
            next.surveys.removeAll {
                $0.timepoint == timepoint && $0.instrument == admin.instrument
            }
            admin.enrollmentId = enrollmentId
            admin.status = .completed
            if admin.completedAt == nil { admin.completedAt = now }
            if admin.startedAt == nil { admin.startedAt = now }
            next.surveys.append(admin)
            do {
                try await api.submitSurvey(admin)
            } catch {
                lastError = error.localizedDescription
            }
        }

        if let total = outcome.iief5Total, let band = outcome.iief5Band {
            lastIIEF5Summary = "IIEF-5 \(total) (\(IIEF5Scoring.displayName(for: band)))"
        }

        let completedInstruments = Set(
            next.surveys
                .filter { $0.timepoint == timepoint && $0.status == .completed }
                .map(\.instrument)
        )
        let required = Set(timepoint.instruments)
        let timepointComplete = required.isSubset(of: completedInstruments)

        if timepointComplete {
            if timepoint == .baseline {
                enrollment.baselineCompletedAt = now
                enrollment.followUpDueAt = Calendar.current.date(
                    byAdding: .day,
                    value: StudyConfig.primaryFollowUpWeek * 7,
                    to: now
                )
                enrollment.status = .baselineComplete
                next.enrollment = enrollment
                next.preferences.demoWeek4Advanced = false
                snapshot = next
                await scheduleReminders(enrollmentId: enrollmentId, baselineCompletedAt: now)
            } else if timepoint == .week4 {
                enrollment.status = .completed
                enrollment.completedAt = now
                next.enrollment = enrollment
                snapshot = next
                do {
                    try await reminders.cancelReminders(enrollmentId: enrollmentId)
                } catch {
                    lastError = error.localizedDescription
                }
            } else {
                next.enrollment = enrollment
                snapshot = next
            }
            await persist()
            path = []
        } else {
            next.enrollment = enrollment
            snapshot = next
            await persist()
        }
    }

    /// Soft recovery if surveys are opened without an enrollment (should be rare).
    private func selectProspectiveArmIfNeededForSurveySave() async {
        guard snapshot.enrollment == nil else { return }
        await ensureParticipant()
        guard let participant = snapshot.participant else { return }
        snapshot.enrollment = StudyEnrollment(
            id: UUID(),
            participantId: participant.id,
            arm: .prospective,
            status: .consented,
            enrolledAt: Date(),
            consentedAt: Date(),
            consentVersion: StudyConfig.consentDocumentVersion,
            baselineCompletedAt: nil,
            followUpDueAt: nil,
            completedAt: nil,
            withdrawnAt: nil,
            meta: .makeNow()
        )
        await persist()
    }

    /// Convenience for stub / branded fallback “complete all” without RK result parsing.
    func completeBaselineSurveys(answers: [Int] = Array(repeating: 3, count: 5)) async {
        let outcome = SurveyTaskOutcome.emptyDefaults(timepoint: .baseline, answers: answers)
        await applySurveyOutcome(outcome, timepoint: .baseline)
    }

    func startWeek4FollowUp() {
        path.append(.week4FollowUp)
    }

    func completeWeek4FollowUp(answers: [Int] = Array(repeating: 3, count: 5)) async {
        let outcome = SurveyTaskOutcome.emptyDefaults(timepoint: .week4, answers: answers)
        await applySurveyOutcome(outcome, timepoint: .week4)
    }

    /// Demo: jump clock so week‑4 is due now (persisted).
    func demoAdvanceToWeek4() async {
        guard var enrollment = snapshot.enrollment else { return }
        guard enrollment.status == .baselineComplete || enrollment.status == .followUpDue else { return }
        let now = Date()
        enrollment.followUpDueAt = now
        enrollment.status = .followUpDue
        snapshot.enrollment = enrollment
        snapshot.preferences.demoWeek4Advanced = true
        await persist()
    }

    /// Demo: seed a full mid-study state (eligible → consented → baseline done).
    func demoSeedBaselineComplete() async {
        await ensureParticipant()
        guard let participant = snapshot.participant else { return }
        let enrollmentId = UUID()
        let now = Date()
        let baselineAt = Calendar.current.date(byAdding: .day, value: -28, to: now) ?? now

        snapshot.enrollment = StudyEnrollment(
            id: enrollmentId,
            participantId: participant.id,
            arm: .prospective,
            status: .baselineComplete,
            enrolledAt: baselineAt,
            consentedAt: baselineAt,
            consentVersion: StudyConfig.consentDocumentVersion,
            baselineCompletedAt: baselineAt,
            followUpDueAt: now,
            completedAt: nil,
            withdrawnAt: nil,
            meta: .makeNow()
        )
        snapshot.consent = ConsentRecord(
            id: UUID(),
            enrollmentId: enrollmentId,
            documentVersion: StudyConfig.consentDocumentVersion,
            signedAt: baselineAt,
            signatureBlobRef: "demo:jeff-walkthrough",
            comprehensionPassed: true,
            meta: .makeNow()
        )
        let outcome = SurveyTaskOutcome.emptyDefaults(
            timepoint: .baseline,
            answers: [3, 3, 3, 3, 3]
        )
        snapshot.surveys = outcome.administrations.map { admin in
            var copy = admin
            copy.enrollmentId = enrollmentId
            return copy
        }
        snapshot.preferences.hasSeenSplash = true
        snapshot.preferences.demoWeek4Advanced = true
        snapshot.enrollment?.status = .followUpDue
        await persist()
        path = []
    }

    func setRemindersEnabled(_ enabled: Bool) async {
        snapshot.preferences.remindersEnabled = enabled
        await persist()
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
        snapshot.preferences.resumeRoute = nil
        await persist()
        path = []
        showSettings = false
    }

    /// Clears on-device LocalStudyStore and in-memory session so demos can restart consent from splash.
    func resetLocalDataForDebug() async {
        if let enrollmentId = snapshot.enrollment?.id {
            try? await reminders.cancelReminders(enrollmentId: enrollmentId)
        }
        do {
            try await store.clear()
        } catch {
            lastError = error.localizedDescription
        }
        snapshot = .empty
        path = []
        lastIIEF5Summary = nil
        lastError = nil
        showSettings = false
        await persist()
    }

    // MARK: - Private

    private func scheduleReminders(enrollmentId: UUID, baselineCompletedAt: Date) async {
        guard snapshot.preferences.remindersEnabled else { return }
        do {
            let authorized = try await reminders.requestAuthorization()
            snapshot.preferences.notificationsAuthorized = authorized
            let schedules = try await reminders.scheduleWeek4FollowUp(
                enrollmentId: enrollmentId,
                baselineCompletedAt: baselineCompletedAt
            )
            snapshot.reminders.removeAll { $0.enrollmentId == enrollmentId }
            snapshot.reminders.append(contentsOf: schedules)
        } catch {
            lastError = error.localizedDescription
        }
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

    /// Latest completed administration for an instrument at a timepoint (for retake prefills).
    func completedSurvey(timepoint: SurveyTimepoint, instrument: InstrumentCode) -> SurveyAdministration? {
        snapshot.surveys.last {
            $0.timepoint == timepoint && $0.instrument == instrument && $0.status == .completed
        }
    }

    private func persistResumeRoute() async {
        let route = path.last
        if snapshot.preferences.resumeRoute != route {
            snapshot.preferences.resumeRoute = route
            await persist()
        }
    }
}

enum AppRoute: Hashable {
    case eligibility
    case consent
    case baselineSurveys
    case week4FollowUp
    case reminders
    case kitStub
    case provider

    var persistedRaw: String {
        switch self {
        case .eligibility: return "eligibility"
        case .consent: return "consent"
        case .baselineSurveys: return "baselineSurveys"
        case .week4FollowUp: return "week4FollowUp"
        case .reminders: return "reminders"
        case .kitStub: return "kitStub"
        case .provider: return "provider"
        }
    }

    init?(persistedRaw: String) {
        switch persistedRaw {
        case "eligibility": self = .eligibility
        case "consent": self = .consent
        case "baselineSurveys": self = .baselineSurveys
        case "week4FollowUp": self = .week4FollowUp
        case "reminders": self = .reminders
        case "kitStub": self = .kitStub
        case "provider": self = .provider
        default: return nil
        }
    }
}
