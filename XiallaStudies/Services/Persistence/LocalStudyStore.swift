import Foundation

/// Local persistence until Cloud Run sync is live. Codable JSON file in Application Support.
protocol StudyStore: Sendable {
    func loadSnapshot() async throws -> StudySnapshot
    func saveSnapshot(_ snapshot: StudySnapshot) async throws
    func clear() async throws
}

/// On-device study progress — survives quit/relaunch for Jeff demos mid-flow.
struct StudySnapshot: Codable, Equatable {
    var participant: ParticipantProfile?
    var enrollment: StudyEnrollment?
    var consent: ConsentRecord?
    var surveys: [SurveyAdministration]
    var reminders: [ReminderSchedule]
    var kit: KitFulfillmentStub?
    /// Lightweight UI / demo preferences that should survive relaunch.
    var preferences: StudyPreferences
    /// Optional consent PDF path under Documents (native export).
    var consentPDFPath: String?
    /// Schema for forward-compatible migrations.
    var schemaVersion: Int

    static let currentSchemaVersion = 2

    static let empty = StudySnapshot(
        participant: nil,
        enrollment: nil,
        consent: nil,
        surveys: [],
        reminders: [],
        kit: nil,
        preferences: .defaults,
        consentPDFPath: nil,
        schemaVersion: currentSchemaVersion
    )
}

struct StudyPreferences: Codable, Equatable {
    /// Skip splash after the first Continue in this install (still shows while loading).
    var hasSeenSplash: Bool
    /// Demo flag: week‑4 follow-up was advanced artificially for walkthrough.
    var demoWeek4Advanced: Bool
    /// Last meaningful route so a mid-flow relaunch can resume (optional).
    var resumeRouteRaw: String?
    /// Notification permission last known (best-effort; OS is source of truth).
    var notificationsAuthorized: Bool?
    /// Settings toggles.
    var remindersEnabled: Bool

    static let defaults = StudyPreferences(
        hasSeenSplash: false,
        demoWeek4Advanced: false,
        resumeRouteRaw: nil,
        notificationsAuthorized: nil,
        remindersEnabled: true
    )

    var resumeRoute: AppRoute? {
        get {
            guard let resumeRouteRaw else { return nil }
            return AppRoute(persistedRaw: resumeRouteRaw)
        }
        set {
            resumeRouteRaw = newValue?.persistedRaw
        }
    }
}

actor LocalStudyStore: StudyStore {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(filename: String = "study-snapshot.json") {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = support.appendingPathComponent("XiallaStudies", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent(filename)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func loadSnapshot() async throws -> StudySnapshot {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .empty
        }
        let data = try Data(contentsOf: fileURL)
        // Decode with migration for schema v1 snapshots that lacked preferences.
        if let snapshot = try? decoder.decode(StudySnapshot.self, from: data) {
            return migrateIfNeeded(snapshot)
        }
        // Legacy v1 without preferences / schemaVersion — decode partial via flexible container.
        if let legacy = try? decoder.decode(LegacyStudySnapshotV1.self, from: data) {
            return StudySnapshot(
                participant: legacy.participant,
                enrollment: legacy.enrollment,
                consent: legacy.consent,
                surveys: legacy.surveys,
                reminders: legacy.reminders,
                kit: legacy.kit,
                preferences: .defaults,
                consentPDFPath: nil,
                schemaVersion: StudySnapshot.currentSchemaVersion
            )
        }
        return .empty
    }

    func saveSnapshot(_ snapshot: StudySnapshot) async throws {
        var copy = snapshot
        copy.schemaVersion = StudySnapshot.currentSchemaVersion
        let data = try encoder.encode(copy)
        try data.write(to: fileURL, options: [.atomic])
    }

    func clear() async throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    private func migrateIfNeeded(_ snapshot: StudySnapshot) -> StudySnapshot {
        var s = snapshot
        if s.schemaVersion < StudySnapshot.currentSchemaVersion {
            s.schemaVersion = StudySnapshot.currentSchemaVersion
        }
        return s
    }
}

/// Pre-preferences snapshot shape for one-shot migration.
private struct LegacyStudySnapshotV1: Codable {
    var participant: ParticipantProfile?
    var enrollment: StudyEnrollment?
    var consent: ConsentRecord?
    var surveys: [SurveyAdministration]
    var reminders: [ReminderSchedule]
    var kit: KitFulfillmentStub?
}
