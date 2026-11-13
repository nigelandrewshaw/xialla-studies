import Foundation

/// Prospective-first observational study (current-user / retrospective is a later add-on).
enum StudyArm: String, Codable, CaseIterable, Identifiable {
    case prospective
    /// Optional add-on — gated until protocol owner approves.
    case currentUserAddOn

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .prospective: return "Starting Xialla"
        case .currentUserAddOn: return "Already using Xialla"
        }
    }

    var isEnabledInV1: Bool {
        switch self {
        case .prospective: return true
        case .currentUserAddOn: return false
        }
    }
}

enum EnrollmentStatus: String, Codable {
    case notStarted
    case eligible
    case consented
    case baselineComplete
    case followUpDue
    case completed
    case withdrawn
}

/// Survey timepoints. V1 ships baseline + week4; 8/12 reserved for later.
enum SurveyTimepoint: String, Codable, CaseIterable, Identifiable {
    case baseline
    case week4
    case week8
    case week12

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .baseline: return "Baseline"
        case .week4: return "Week 4 follow-up"
        case .week8: return "Week 8 follow-up"
        case .week12: return "Week 12 follow-up"
        }
    }

    /// Instruments enabled in app v1.
    var isEnabledInV1: Bool {
        switch self {
        case .baseline, .week4: return true
        case .week8, .week12: return false
        }
    }

    var followUpWeek: Int? {
        switch self {
        case .baseline: return nil
        case .week4: return 4
        case .week8: return 8
        case .week12: return 12
        }
    }

    /// Instruments for this timepoint — each can be opened independently from the list.
    var instruments: [InstrumentCode] {
        switch self {
        case .baseline:
            return [.iief5, .baselineHistory, .usability, .comfort, .satisfaction, .adverseEvents, .freeText]
        case .week4, .week8, .week12:
            return [.iief5, .usability, .comfort, .satisfaction, .adverseEvents, .freeText]
        }
    }
}

enum InstrumentCode: String, Codable, CaseIterable, Identifiable {
    case iief5
    case baselineHistory
    case usability
    case comfort
    case satisfaction
    case adverseEvents
    case freeText

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .iief5: return "IIEF-5"
        case .baselineHistory: return "Baseline history"
        case .usability: return "Usability"
        case .comfort: return "Comfort"
        case .satisfaction: return "Satisfaction"
        case .adverseEvents: return "Adverse events"
        case .freeText: return "Free text"
        }
    }
}

struct StudyRecordMeta: Codable, Equatable {
    var studyCode: String
    var siteCode: String
    var recordedAt: Date

    static func makeNow(
        studyCode: String = StudyConfig.studyCode,
        siteCode: String = StudyConfig.siteCode
    ) -> StudyRecordMeta {
        StudyRecordMeta(studyCode: studyCode, siteCode: siteCode, recordedAt: Date())
    }
}

struct ParticipantProfile: Codable, Equatable, Identifiable {
    var id: UUID
    var createdAt: Date
    var localeIdentifier: String
    var appVersion: String
    /// Linked Xialla customer id when auth bridge exists.
    var xiallaCustomerId: String?
    var meta: StudyRecordMeta
}

struct StudyEnrollment: Codable, Equatable, Identifiable {
    var id: UUID
    var participantId: UUID
    var arm: StudyArm
    var status: EnrollmentStatus
    var enrolledAt: Date?
    var consentedAt: Date?
    var consentVersion: String?
    var baselineCompletedAt: Date?
    var followUpDueAt: Date?
    var completedAt: Date?
    var withdrawnAt: Date?
    var meta: StudyRecordMeta
}

struct ConsentRecord: Codable, Equatable, Identifiable {
    var id: UUID
    var enrollmentId: UUID
    var documentVersion: String
    var signedAt: Date
    /// Local stub reference for signature image / PDF blob.
    var signatureBlobRef: String?
    var comprehensionPassed: Bool
    var meta: StudyRecordMeta
}

struct SurveyAdministration: Codable, Equatable, Identifiable {
    var id: UUID
    var enrollmentId: UUID
    var instrument: InstrumentCode
    var timepoint: SurveyTimepoint
    var status: AdministrationStatus
    var startedAt: Date?
    var completedAt: Date?
    var responses: [SurveyResponseItem]
    var scoreTotal: Int?
    var scoreBand: String?
    var meta: StudyRecordMeta
}

enum AdministrationStatus: String, Codable {
    case notStarted
    case inProgress
    case completed
    case skipped
}

struct SurveyResponseItem: Codable, Equatable, Identifiable {
    var id: UUID
    var itemCode: String
    var value: String
    var answeredAt: Date
}

struct ReminderSchedule: Codable, Equatable, Identifiable {
    var id: UUID
    var enrollmentId: UUID
    var kind: ReminderKind
    var fireAt: Date
    var channel: ReminderChannel
    var status: ReminderStatus
    var meta: StudyRecordMeta
}

enum ReminderKind: String, Codable {
    case week4FollowUp
    // Reserved for later protocol versions:
    case week8FollowUp
    case week12FollowUp
}

enum ReminderChannel: String, Codable {
    case local
    case push
    case both
}

enum ReminderStatus: String, Codable {
    case scheduled
    case sent
    case cancelled
    case completed
}

/// Kit fulfillment timing TBD with Jeff — stub only.
struct KitFulfillmentStub: Codable, Equatable, Identifiable {
    var id: UUID
    var enrollmentId: UUID
    var status: KitFulfillmentStatus
    var notes: String?
    var meta: StudyRecordMeta
}

enum KitFulfillmentStatus: String, Codable {
    case notRequested
    case pendingDecision
    case queued
    case shipped
    case cancelled
}
