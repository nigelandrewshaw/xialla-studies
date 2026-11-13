import Foundation

/// Backend will be Cloud Run + Postgres. Client talks only through this protocol.
protocol StudyAPIClient: Sendable {
    func fetchStatus(participantId: UUID) async throws -> EnrollmentStatusDTO
    func submitConsent(_ record: ConsentRecord) async throws
    func submitSurvey(_ administration: SurveyAdministration) async throws
    func registerPushToken(_ token: String, participantId: UUID) async throws
    func withdraw(enrollmentId: UUID, reason: String?) async throws
}

struct EnrollmentStatusDTO: Codable, Equatable {
    var enrollmentId: UUID?
    var status: EnrollmentStatus
    var arm: StudyArm?
    var followUpDueAt: Date?
    var studyCode: String
    var siteCode: String
}

/// Local / offline stub — no network. Replace with `LiveStudyAPIClient` when Cloud Run exists.
actor StubStudyAPIClient: StudyAPIClient {
    private var lastConsent: ConsentRecord?
    private var surveys: [SurveyAdministration] = []
    private var withdrawn: Set<UUID> = []

    func fetchStatus(participantId: UUID) async throws -> EnrollmentStatusDTO {
        EnrollmentStatusDTO(
            enrollmentId: nil,
            status: .notStarted,
            arm: .prospective,
            followUpDueAt: nil,
            studyCode: StudyConfig.studyCode,
            siteCode: StudyConfig.siteCode
        )
    }

    func submitConsent(_ record: ConsentRecord) async throws {
        lastConsent = record
    }

    func submitSurvey(_ administration: SurveyAdministration) async throws {
        surveys.append(administration)
    }

    func registerPushToken(_ token: String, participantId: UUID) async throws {
        // no-op stub
    }

    func withdraw(enrollmentId: UUID, reason: String?) async throws {
        withdrawn.insert(enrollmentId)
    }
}

/// Placeholder for the future HTTPS client. Methods throw until implemented.
actor LiveStudyAPIClient: StudyAPIClient {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL = StudyConfig.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchStatus(participantId: UUID) async throws -> EnrollmentStatusDTO {
        throw StudyAPIError.notImplemented("GET /me/status")
    }

    func submitConsent(_ record: ConsentRecord) async throws {
        throw StudyAPIError.notImplemented("POST /consent")
    }

    func submitSurvey(_ administration: SurveyAdministration) async throws {
        throw StudyAPIError.notImplemented("POST /surveys/responses")
    }

    func registerPushToken(_ token: String, participantId: UUID) async throws {
        throw StudyAPIError.notImplemented("POST /devices/push-token")
    }

    func withdraw(enrollmentId: UUID, reason: String?) async throws {
        throw StudyAPIError.notImplemented("POST /withdraw")
    }
}

enum StudyAPIError: Error, LocalizedError {
    case notImplemented(String)
    case unauthorized
    case server(status: Int)

    var errorDescription: String? {
        switch self {
        case .notImplemented(let path):
            return "API stub: \(path) is not wired yet."
        case .unauthorized:
            return "Not authorized."
        case .server(let status):
            return "Server error (\(status))."
        }
    }
}
