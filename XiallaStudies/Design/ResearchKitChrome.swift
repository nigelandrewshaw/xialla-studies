import SwiftUI
import UIKit

#if canImport(ResearchKit) && canImport(ResearchKitUI)
import ResearchKit
import ResearchKitUI

/// Brands ResearchKit task chrome: tan tint, Fieldwork Geo type, square aspect-fit icons,
/// and scroll insets so body copy clears the sticky Next footer.
enum ResearchKitChrome {
    /// Slightly smaller than system body so long consent copy fits / scrolls cleanly.
    static let bodyPointSize: CGFloat = 14
    static let titlePointSize: CGFloat = 22

    private static var didApplyAppearance = false

    /// Call once when presenting an ORK task. Safe to call repeatedly.
    static func applyAppearance() {
        guard !didApplyAppearance else { return }
        didApplyAppearance = true

        let tan = UIColor(BrandTheme.tan)
        UIView.appearance(whenContainedInInstancesOf: [ORKTaskViewController.self]).tintColor = tan
        UINavigationBar.appearance(whenContainedInInstancesOf: [ORKTaskViewController.self]).tintColor = tan
    }

    /// Tint + appearance for a freshly created task view controller.
    static func style(_ taskViewController: ORKTaskViewController) {
        applyAppearance()
        taskViewController.view.tintColor = UIColor(BrandTheme.tan)
        taskViewController.view.backgroundColor = .white
    }

    /// Re-apply Fieldwork fonts and icon aspect after ORK labels reset their own defaults.
    static func polishStepView(_ root: UIView) {
        applyFieldworkFonts(in: root)
        preserveIconAspect(in: root)
        ensureScrollClearsFooter(in: root)
    }

    // MARK: - Fonts

    static func fieldworkFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let name: String
        switch weight {
        case .semibold, .bold, .heavy, .black:
            name = BrandTheme.fieldworkBoldName
        case .medium:
            name = BrandTheme.fieldworkDemiboldName
        default:
            name = BrandTheme.fieldworkRegularName
        }
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }

    private static func applyFieldworkFonts(in root: UIView) {
        func walk(_ view: UIView) {
            if let label = view as? UILabel, shouldBrand(label) {
                let size = targetPointSize(for: label)
                let weight = inferredWeight(for: label)
                label.font = fieldworkFont(size: size, weight: weight)
                label.numberOfLines = 0
                label.lineBreakMode = .byWordWrapping
                label.adjustsFontForContentSizeCategory = false
            }
            view.subviews.forEach(walk)
        }
        walk(root)
    }

    private static func shouldBrand(_ label: UILabel) -> Bool {
        // Skip tiny chrome / progress glyphs.
        let text = label.text ?? label.attributedText?.string ?? ""
        if text.count <= 1 { return false }
        return true
    }

    private static func targetPointSize(for label: UILabel) -> CGFloat {
        let current = label.font?.pointSize ?? bodyPointSize
        let name = NSStringFromClass(type(of: label))
        if name.contains("Title") || name.contains("Headline") {
            return min(current, titlePointSize)
        }
        if name.contains("Subheadline") || name.contains("Caption") || name.contains("Footnote") {
            return min(current, bodyPointSize)
        }
        // Body / detail / default — slightly smaller than RK Liquid Glass Title2 (22).
        if current >= 18 {
            return bodyPointSize
        }
        return min(current, bodyPointSize + 1)
    }

    private static func inferredWeight(for label: UILabel) -> UIFont.Weight {
        let traits = label.font?.fontDescriptor.symbolicTraits ?? []
        if traits.contains(.traitBold) { return .bold }
        let name = NSStringFromClass(type(of: label))
        if name.contains("Title") || name.contains("Headline") { return .semibold }
        return .regular
    }

    // MARK: - Icons

    /// Keep consent / instruction icons square and aspect-fit (no horizontal squash).
    private static func preserveIconAspect(in root: UIView) {
        func walk(_ view: UIView) {
            if let imageView = view as? UIImageView, isLikelyStepIcon(imageView) {
                imageView.contentMode = .scaleAspectFit
                imageView.clipsToBounds = true
                // Prefer intrinsic square: resist horizontal stretch from wide parents.
                imageView.setContentHuggingPriority(.required, for: .horizontal)
                imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
                imageView.setContentHuggingPriority(.required, for: .vertical)
                imageView.setContentCompressionResistancePriority(.required, for: .vertical)
                if imageView.constraints.contains(where: { $0.firstAttribute == .width || $0.firstAttribute == .height }) == false {
                    // Matches ResearchKit's ORKStepContentIconImageViewDimension (~80pt square).
                    let side: CGFloat = 80
                    imageView.widthAnchor.constraint(equalToConstant: side).isActive = true
                    imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
                } else {
                    // If both width & height exist but differ, equalize to the smaller side.
                    equalizeSquareConstraints(on: imageView)
                }
            }
            view.subviews.forEach(walk)
        }
        walk(root)
    }

    private static func isLikelyStepIcon(_ imageView: UIImageView) -> Bool {
        if imageView.image?.isSymbolImage == true { return true }
        let bounds = imageView.bounds
        if bounds.width > 0, bounds.height > 0, bounds.width <= 120, bounds.height <= 120 {
            return true
        }
        // Icon slot before layout — accessibility id used by ORK for title icon.
        let id = imageView.accessibilityIdentifier ?? ""
        if id.localizedCaseInsensitiveContains("icon") { return true }
        // Heuristic: small fixed constraints (~80–100) from ORKStepContentIconImageViewDimension.
        for c in imageView.constraints where c.firstAttribute == .width || c.firstAttribute == .height {
            if c.constant > 40, c.constant <= 120 { return true }
        }
        return false
    }

    private static func equalizeSquareConstraints(on imageView: UIImageView) {
        var width: NSLayoutConstraint?
        var height: NSLayoutConstraint?
        for c in imageView.constraints {
            if c.firstItem === imageView, c.firstAttribute == .width, c.secondItem == nil {
                width = c
            }
            if c.firstItem === imageView, c.firstAttribute == .height, c.secondItem == nil {
                height = c
            }
        }
        guard let width, let height else { return }
        let side = min(width.constant, height.constant)
        width.constant = side
        height.constant = side
    }

    // MARK: - Scroll

    /// Ensure scrollable step content can clear the sticky Next footer.
    private static func ensureScrollClearsFooter(in root: UIView) {
        let footerReserve: CGFloat = 96
        func walk(_ view: UIView) {
            if let scroll = view as? UIScrollView {
                var inset = scroll.contentInset
                if inset.bottom < footerReserve {
                    inset.bottom = footerReserve
                    scroll.contentInset = inset
                    scroll.scrollIndicatorInsets = inset
                    scroll.alwaysBounceVertical = true
                    scroll.clipsToBounds = true
                }
            }
            view.subviews.forEach(walk)
        }
        walk(root)
    }

}

#else

enum ResearchKitChrome {
    static func applyAppearance() {}
}

#endif
