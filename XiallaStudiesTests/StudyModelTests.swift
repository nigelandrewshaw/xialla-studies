import XCTest
@testable import XiallaStudies

final class StudyModelTests: XCTestCase {
    func testV1FollowUpIsWeek4Only() {
        XCTAssertEqual(StudyConfig.followUpWeeks, [4])
        XCTAssertTrue(SurveyTimepoint.week4.isEnabledInV1)
        XCTAssertFalse(SurveyTimepoint.week8.isEnabledInV1)
        XCTAssertFalse(SurveyTimepoint.week12.isEnabledInV1)
    }

    func testProspectiveArmEnabledCurrentUserDisabled() {
        XCTAssertTrue(StudyArm.prospective.isEnabledInV1)
        XCTAssertFalse(StudyArm.currentUserAddOn.isEnabledInV1)
    }

    func testRecordMetaCarriesStudyAndSiteCodes() {
        let meta = StudyRecordMeta.makeNow(studyCode: "DEMO_STUDY", siteCode: "SJH_LON")
        XCTAssertEqual(meta.studyCode, "DEMO_STUDY")
        XCTAssertEqual(meta.siteCode, "SJH_LON")
    }

    func testIIEF5ScoreBandsHelper() {
        XCTAssertEqual(IIEF5Scoring.band(for: 8), .severe)
        XCTAssertEqual(IIEF5Scoring.band(for: 12), .moderate)
        XCTAssertEqual(IIEF5Scoring.band(for: 18), .mildToModerate)
        XCTAssertEqual(IIEF5Scoring.band(for: 22), .mild)
        XCTAssertEqual(IIEF5Scoring.band(for: 25), .none)
    }

    func testSnapshotRoundTrip() throws {
        let enrollmentId = UUID()
        let snapshot = StudySnapshot(
            participant: ParticipantProfile(
                id: UUID(),
                createdAt: Date(timeIntervalSince1970: 1_700_000_000),
                localeIdentifier: "en_CA",
                appVersion: "0.1.0",
                xiallaCustomerId: nil,
                meta: .makeNow()
            ),
            enrollment: StudyEnrollment(
                id: enrollmentId,
                participantId: UUID(),
                arm: .prospective,
                status: .baselineComplete,
                enrolledAt: Date(timeIntervalSince1970: 1_700_000_000),
                consentedAt: Date(timeIntervalSince1970: 1_700_000_100),
                consentVersion: "0.1.0-stub",
                baselineCompletedAt: Date(timeIntervalSince1970: 1_700_000_200),
                followUpDueAt: Date(timeIntervalSince1970: 1_700_000_200 + 28 * 86_400),
                completedAt: nil,
                withdrawnAt: nil,
                meta: .makeNow()
            ),
            consent: nil,
            surveys: [],
            reminders: [],
            kit: KitFulfillmentStub(
                id: UUID(),
                enrollmentId: enrollmentId,
                status: .pendingDecision,
                notes: "stub",
                meta: .makeNow()
            )
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(StudySnapshot.self, from: data)
        XCTAssertEqual(decoded.enrollment?.arm, .prospective)
        XCTAssertEqual(decoded.kit?.status, .pendingDecision)
    }
}
