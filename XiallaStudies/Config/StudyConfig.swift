import Foundation

/// Study and site identifiers attached to every persisted / synced record.
/// Replace placeholders before pilot enrollment.
enum StudyConfig {
    /// Protocol study code (placeholder until IRB / ops assign final code).
    static let studyCode = "STUDY_CODE"

    /// First site: Dr. Jeffrey Campbell / St. Joseph’s London (placeholder code).
    static let siteCode = "SITE_CODE"

    /// Suggested App Store / Xcode bundle identifier.
    static let suggestedBundleIdentifier = "com.xialla.studies"

    /// App display name.
    static let appDisplayName = "Xialla Studies"

    /// Consent document version — bump when IRB-approved text changes.
    static let consentDocumentVersion = "0.1.0-stub"

    /// Prospective follow-up offset for v1 (weeks). Structure allows 8/12 later.
    static let followUpWeeks: [Int] = [4]

    /// Primary follow-up timepoint for v1.
    static let primaryFollowUpWeek = 4

    /// Local reminder lead days before follow-up due (optional nudges).
    static let reminderLeadDays: [Int] = [3, 0]

    /// API base URL placeholder (Cloud Run later).
    static let apiBaseURL = URL(string: "https://study-api.example.invalid/v1")!
}
