import Foundation

/// Native consent artifact helper — signature PNG + lightweight PDF via `ConsentSignatureStore`.
enum ConsentPDFExporter {
    /// Writes (or reuses) the local consent PDF path when available.
    static func existingPDFURL(version: String = StudyConfig.consentDocumentVersion) -> URL? {
        let url = ConsentSignatureStore.documentsDirectory()
            .appendingPathComponent("xialla-consent-\(version).pdf")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
