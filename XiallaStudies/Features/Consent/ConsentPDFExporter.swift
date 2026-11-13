import Foundation

#if canImport(ResearchKit)
import ResearchKit

enum ConsentPDFExporter {
    /// Writes a participant consent PDF to the app Documents directory when ResearchKit can render it.
    static func export(document: ORKConsentDocument?, completion: @escaping (URL?) -> Void) {
        guard let document else {
            completion(nil)
            return
        }
        document.makePDF { data, error in
            guard let data, error == nil else {
                completion(nil)
                return
            }
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("xialla-consent-\(StudyConfig.consentDocumentVersion).pdf")
            do {
                try data.write(to: url, options: .atomic)
                completion(url)
            } catch {
                completion(nil)
            }
        }
    }
}

#else

enum ConsentPDFExporter {
    static func export(document: Any?, completion: @escaping (URL?) -> Void) {
        completion(nil)
    }
}

#endif
