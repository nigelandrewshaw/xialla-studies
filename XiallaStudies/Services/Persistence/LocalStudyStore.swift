import Foundation

/// Local persistence until Cloud Run sync is live. Codable JSON file in Application Support.
protocol StudyStore: Sendable {
    func loadSnapshot() async throws -> StudySnapshot
    func saveSnapshot(_ snapshot: StudySnapshot) async throws
}

struct StudySnapshot: Codable, Equatable {
    var participant: ParticipantProfile?
    var enrollment: StudyEnrollment?
    var consent: ConsentRecord?
    var surveys: [SurveyAdministration]
    var reminders: [ReminderSchedule]
    var kit: KitFulfillmentStub?

    static let empty = StudySnapshot(
        participant: nil,
        enrollment: nil,
        consent: nil,
        surveys: [],
        reminders: [],
        kit: nil
    )
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
        return try decoder.decode(StudySnapshot.self, from: data)
    }

    func saveSnapshot(_ snapshot: StudySnapshot) async throws {
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }
}
