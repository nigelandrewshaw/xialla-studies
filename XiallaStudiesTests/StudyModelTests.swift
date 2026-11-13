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
        // Standard IIEF-5 bands: 5–7 severe, 8–11 moderate, 12–16 mild–moderate, 17–21 mild, 22–25 none
        XCTAssertEqual(IIEF5Scoring.band(for: 6), .severe)
        XCTAssertEqual(IIEF5Scoring.band(for: 8), .moderate)
        XCTAssertEqual(IIEF5Scoring.band(for: 12), .mildToModerate)
        XCTAssertEqual(IIEF5Scoring.band(for: 18), .mild)
        XCTAssertEqual(IIEF5Scoring.band(for: 22), .none)
        XCTAssertEqual(IIEF5Scoring.band(for: 25), .none)
        XCTAssertEqual(IIEF5Scoring.total(answers: [3, 3, 3, 3, 3]), 15)
        XCTAssertEqual(IIEF5Scoring.band(for: 15), .mildToModerate)
    }

    func testIIEF5OfficialItemWording() {
        XCTAssertEqual(IIEF5Scoring.items.count, 5)
        XCTAssertEqual(IIEF5Scoring.itemPrompts.count, 5)
        XCTAssertEqual(
            IIEF5Scoring.items[0].prompt,
            "How do you rate your confidence that you could get and keep an erection?"
        )
        XCTAssertEqual(
            IIEF5Scoring.items[4].prompt,
            "When you attempted sexual intercourse, how often was it satisfactory for you?"
        )
        XCTAssertTrue(IIEF5Scoring.recallPeriodInstruction.contains("six months"))
    }

    func testStudyParametersProviderIsJeff() {
        let provider = StudyConfig.provider
        XCTAssertEqual(provider.displayName, "Dr. Jeffrey Campbell")
        XCTAssertEqual(provider.photoAssetName, "DrJeffreyCampbell")
        XCTAssertTrue(provider.organization.contains("Joseph"))
    }

    func testStudyAndSiteCodesAreRealDemoValues() {
        XCTAssertEqual(StudyConfig.studyCode, "XIALLA-OBS-V1")
        XCTAssertEqual(StudyConfig.siteCode, "SJH-LON")
        XCTAssertNotEqual(StudyConfig.studyCode, "STUDY_CODE")
        XCTAssertNotEqual(StudyConfig.siteCode, "SITE_CODE")
    }

    func testSnapshotRoundTripIncludesPreferences() throws {
        let enrollmentId = UUID()
        var prefs = StudyPreferences.defaults
        prefs.hasSeenSplash = true
        prefs.demoWeek4Advanced = true
        prefs.resumeRoute = .week4FollowUp
        prefs.remindersEnabled = true

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
            surveys: [
                SurveyAdministration(
                    id: UUID(),
                    enrollmentId: enrollmentId,
                    instrument: .iief5,
                    timepoint: .baseline,
                    status: .completed,
                    startedAt: Date(timeIntervalSince1970: 1_700_000_200),
                    completedAt: Date(timeIntervalSince1970: 1_700_000_200),
                    responses: (1...5).map {
                        SurveyResponseItem(
                            id: UUID(),
                            itemCode: "iief5.q\($0)",
                            value: "3",
                            answeredAt: Date(timeIntervalSince1970: 1_700_000_200)
                        )
                    },
                    scoreTotal: 15,
                    scoreBand: "mild-to-moderate",
                    meta: .makeNow()
                )
            ],
            reminders: [],
            kit: KitFulfillmentStub(
                id: UUID(),
                enrollmentId: enrollmentId,
                status: .pendingDecision,
                notes: "stub",
                meta: .makeNow()
            ),
            preferences: prefs,
            consentPDFPath: nil,
            schemaVersion: StudySnapshot.currentSchemaVersion
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(StudySnapshot.self, from: data)
        XCTAssertEqual(decoded.enrollment?.arm, .prospective)
        XCTAssertEqual(decoded.kit?.status, .pendingDecision)
        XCTAssertTrue(decoded.preferences.hasSeenSplash)
        XCTAssertTrue(decoded.preferences.demoWeek4Advanced)
        XCTAssertEqual(decoded.preferences.resumeRoute, .week4FollowUp)
        XCTAssertEqual(decoded.surveys.first?.scoreTotal, 15)
    }

    func testLocalStudyStorePersistsAndClears() async throws {
        let store = LocalStudyStore(filename: "test-snapshot-\(UUID().uuidString).json")
        var snap = StudySnapshot.empty
        snap.preferences.hasSeenSplash = true
        snap.preferences.demoWeek4Advanced = true
        try await store.saveSnapshot(snap)
        let loaded = try await store.loadSnapshot()
        XCTAssertTrue(loaded.preferences.hasSeenSplash)
        XCTAssertTrue(loaded.preferences.demoWeek4Advanced)
        try await store.clear()
        let cleared = try await store.loadSnapshot()
        XCTAssertFalse(cleared.preferences.hasSeenSplash)
    }
}
