import Foundation

/// Per-study parameters that will eventually load from the study DB.
/// Jeff demo ships a single hardcoded `StudyParameters.xiallaObservationalV1` via `StudyConfig`.
struct StudyParameters: Codable, Equatable, Sendable {
    var studyCode: String
    var siteCode: String
    var consentDocumentVersion: String
    var primaryFollowUpWeek: Int
    var followUpWeeks: [Int]
    var reminderLeadDays: [Int]
    var apiBaseURLString: String
    var provider: StudyProviderParameters

    var apiBaseURL: URL {
        URL(string: apiBaseURLString) ?? URL(string: "https://study-api.example.invalid/v1")!
    }
}

/// Participating investigator / site contact — DB-backed later; hardcoded for the Jeff demo.
struct StudyProviderParameters: Codable, Equatable, Sendable, Identifiable {
    var id: String
    var displayName: String
    var credentials: String
    var title: String
    var specialty: String
    var organization: String
    var location: String
    var phone: String?
    var email: String?
    /// Bundled asset name in Assets.xcassets (preferred for offline demo).
    var photoAssetName: String?
    /// Remote portrait URL (future DB / CDN); unused when asset is present.
    var photoURLString: String?
    var profileURLString: String?
    var bio: String

    var profileURL: URL? {
        profileURLString.flatMap { URL(string: $0) }
    }

    var photoURL: URL? {
        photoURLString.flatMap { URL(string: $0) }
    }
}

extension StudyParameters {
    /// Temporary hardcode for the Xialla observational v1 / Jeff demo.
    /// Replace with a fetch keyed by `studyCode` + `siteCode` when the API exists.
    /// Demo codes: Observational Study v1.0 / first site St. Joseph’s London (`XIALLA-OBS-V1` · `SJH-LON`).
    static let xiallaObservationalV1 = StudyParameters(
        studyCode: "XIALLA-OBS-V1",
        siteCode: "SJH-LON",
        consentDocumentVersion: "0.2.0-native",
        primaryFollowUpWeek: 4,
        followUpWeeks: [4],
        reminderLeadDays: [3, 0],
        apiBaseURLString: "https://study-api.example.invalid/v1",
        provider: .jeffreyCampbell
    )
}

extension StudyProviderParameters {
    /// First site investigator — sourced from https://xialla.com/blogs/providers/campbell-jeffrey
    static let jeffreyCampbell = StudyProviderParameters(
        id: "provider.jeffrey-campbell",
        displayName: "Dr. Jeffrey Campbell",
        credentials: "MD, MPH, FRCSC",
        title: "Assistant Professor, Division of Urology",
        specialty: "Men’s health, sexual dysfunction, BPH/LUTS, reconstructive urology",
        organization: "St. Joseph’s Hospital · Western University",
        location: "London, Ontario",
        phone: "519.646.6087",
        email: "amelia.gallagher@sjhc.london.on.ca",
        photoAssetName: "DrJeffreyCampbell",
        photoURLString: "https://xialla.com/cdn/shop/articles/Jeffrey_Campbell_5dba51e3-5c09-4864-b322-9ed5d4070a44.jpg?v=1742308306&width=1200",
        profileURLString: "https://xialla.com/blogs/providers/campbell-jeffrey",
        bio: """
        Dr. Campbell completed medical school at Dalhousie University, Urology residency at Western University, \
        a fellowship in men’s health and reconstructive urology at Johns Hopkins, and a second fellowship in \
        prosthetic surgery at Western. He also holds an MPH from the Johns Hopkins Bloomberg School of Public Health.

        He is an Assistant Professor in the Department of Surgery, Division of Urology at the Schulich School of \
        Medicine and Dentistry, Western University. His practice focuses on benign urology, BPH/LUTS, men’s health, \
        and sexual dysfunction. Clinical research includes minimally invasive BPH treatments and new options for \
        erectile dysfunction and Peyronie’s disease.
        """
    )
}
