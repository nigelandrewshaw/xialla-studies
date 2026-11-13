import Foundation

/// Active study configuration. Today: hardcoded `StudyParameters.xiallaObservationalV1`.
/// Later: swap `active` from a DB/API payload per enrolled study without rewriting screens.
enum StudyConfig {
    /// Mutable hook for future remote load; demo uses the static observational v1 pack.
    static var active: StudyParameters = .xiallaObservationalV1

    static var studyCode: String { active.studyCode }
    static var siteCode: String { active.siteCode }
    static var consentDocumentVersion: String { active.consentDocumentVersion }
    static var followUpWeeks: [Int] { active.followUpWeeks }
    static var primaryFollowUpWeek: Int { active.primaryFollowUpWeek }
    static var reminderLeadDays: [Int] { active.reminderLeadDays }
    static var apiBaseURL: URL { active.apiBaseURL }
    static var provider: StudyProviderParameters { active.provider }

    /// Suggested App Store / Xcode bundle identifier.
    static let suggestedBundleIdentifier = "com.xialla.studies"

    /// App display name.
    static let appDisplayName = "Xialla Studies"
}
