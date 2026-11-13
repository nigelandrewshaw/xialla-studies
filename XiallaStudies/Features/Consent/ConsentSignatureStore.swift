import Foundation
import UIKit
import PencilKit

/// Persists participant signature PNG (+ optional simple PDF) under Documents.
enum ConsentSignatureStore {
    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Saves signature PNG; returns a local blob reference and file URL.
    static func saveSignaturePNG(
        _ data: Data,
        version: String = StudyConfig.consentDocumentVersion
    ) throws -> (ref: String, url: URL) {
        let filename = "xialla-consent-signature-\(version).png"
        let url = documentsDirectory().appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return ("local-signature:\(filename)", url)
    }

    /// Builds a lightweight consent PDF (sections + typed name + signature image + date).
    static func exportPDF(
        firstName: String,
        lastName: String,
        signedAt: Date,
        signaturePNG: Data?,
        version: String = StudyConfig.consentDocumentVersion
    ) -> URL? {
        let url = documentsDirectory()
            .appendingPathComponent("xialla-consent-\(version).pdf")
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                var y: CGFloat = 48
                let left: CGFloat = 48
                let width = pageRect.width - 96

                func draw(_ text: String, font: UIFont, color: UIColor = .black) {
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: color
                    ]
                    let rect = CGRect(x: left, y: y, width: width, height: 700)
                    let ns = text as NSString
                    let used = ns.boundingRect(
                        with: CGSize(width: width, height: 2000),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: attrs,
                        context: nil
                    )
                    ns.draw(in: CGRect(x: left, y: y, width: width, height: ceil(used.height)), withAttributes: attrs)
                    y += ceil(used.height) + 10
                    if y > pageRect.height - 72 {
                        context.beginPage()
                        y = 48
                    }
                }

                draw(ConsentDocumentCopy.documentTitle, font: .boldSystemFont(ofSize: 18))
                draw(
                    "Consent document version \(version)",
                    font: .systemFont(ofSize: 11),
                    color: .darkGray
                )
                y += 6

                for section in ConsentDocumentCopy.reviewSections {
                    draw(section.title, font: .boldSystemFont(ofSize: 14))
                    draw(section.body, font: .systemFont(ofSize: 11))
                    y += 4
                }

                draw(ConsentDocumentCopy.reasonForConsent, font: .italicSystemFont(ofSize: 12))
                y += 8

                let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                let formatter = DateFormatter()
                formatter.dateStyle = .long
                formatter.timeStyle = .short
                draw("Participant: \(name)", font: .systemFont(ofSize: 12))
                draw("Signed: \(formatter.string(from: signedAt))", font: .systemFont(ofSize: 12))

                if let signaturePNG, let image = UIImage(data: signaturePNG) {
                    y += 8
                    draw("Signature:", font: .systemFont(ofSize: 12))
                    let maxWidth: CGFloat = width
                    let maxHeight: CGFloat = 100
                    let aspect = image.size.width / max(image.size.height, 1)
                    var drawWidth = maxWidth
                    var drawHeight = drawWidth / aspect
                    if drawHeight > maxHeight {
                        drawHeight = maxHeight
                        drawWidth = drawHeight * aspect
                    }
                    if y + drawHeight > pageRect.height - 48 {
                        context.beginPage()
                        y = 48
                    }
                    image.draw(in: CGRect(x: left, y: y, width: drawWidth, height: drawHeight))
                }
            }
            return url
        } catch {
            return nil
        }
    }
}
