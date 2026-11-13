import SwiftUI

/// Xialla study visual tokens — aligned with xialla.com (ink chrome + product teal).
/// Fieldwork (Adobe Fonts / Typekit) cannot be legally redistributed as an app binary;
/// we match weights with Avenir Next (geometric humanist sans) until a desktop Fieldwork
/// license is added under `Resources/Fonts/` + `UIAppFonts`. See `docs/BUILD_NOTES.md`.
enum BrandTheme {
    // MARK: - Colors (from xialla.com CSS tokens + product teal)

    /// Site ink — `--text-color` / `--accent` ≈ rgb(28, 28, 28).
    static let ink = Color(red: 28 / 255, green: 28 / 255, blue: 28 / 255)

    /// Secondary text — site muted (~65% of ink on light).
    static let graphite = Color(red: 0.40, green: 0.40, blue: 0.40)

    /// Light surface — site `--background` light scheme ≈ rgb(239, 239, 239).
    static let parchment = Color(red: 239 / 255, green: 239 / 255, blue: 239 / 255)

    /// Cool mist for gradients (hero teal-gray from homepage imagery).
    static let mist = Color(red: 0.78, green: 0.84, blue: 0.84)

    /// Product teal — Xialla device / medical silicone accent (not hospital blue).
    static let teal = Color(red: 18 / 255, green: 92 / 255, blue: 96 / 255)

    /// Soft teal highlight for focus / progress.
    static let tealSoft = Color(red: 0.22, green: 0.52, blue: 0.54)

    /// Attention (reminders / AE) — restrained amber.
    static let attention = Color(red: 0.72, green: 0.45, blue: 0.18)

    /// Success / completion — site success-text ≈ rgb(48, 122, 7) softened.
    static let success = Color(red: 48 / 255, green: 122 / 255, blue: 7 / 255)

    /// Pure white for overlays on dark hero.
    static let chalk = Color.white

    // MARK: - Gradients

    static var atmosphere: LinearGradient {
        LinearGradient(
            colors: [
                parchment,
                mist.opacity(0.55),
                teal.opacity(0.14)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var heroWash: LinearGradient {
        LinearGradient(
            colors: [
                ink.opacity(0.55),
                Color(red: 0.05, green: 0.18, blue: 0.20).opacity(0.72),
                teal.opacity(0.78)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Typography

    /// PostScript names for bundled Fieldwork (when licensed desktop fonts are dropped in).
    static let fieldworkRegularName = "Fieldwork-Regular"
    static let fieldworkSemiboldName = "Fieldwork-Semibold"
    static let fieldworkBoldName = "Fieldwork-Bold"

    /// Display / brand face — Fieldwork when bundled, else Avenir Next.
    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if UIFont(name: fieldworkName(for: weight), size: size) != nil {
            return .custom(fieldworkName(for: weight), size: size)
        }
        return .custom(avenirName(for: weight), size: size)
    }

    /// Body / UI face — same Fieldwork family at text sizes when available.
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if UIFont(name: fieldworkName(for: weight), size: size) != nil {
            return .custom(fieldworkName(for: weight), size: size)
        }
        return .custom(avenirName(for: weight), size: size)
    }

    private static func fieldworkName(for weight: Font.Weight) -> String {
        switch weight {
        case .semibold, .bold, .heavy, .black: return fieldworkBoldName
        case .medium: return fieldworkSemiboldName
        default: return fieldworkRegularName
        }
    }

    private static func avenirName(for weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black: return "AvenirNext-Bold"
        case .semibold, .medium: return "AvenirNext-DemiBold"
        case .light, .thin, .ultraLight: return "AvenirNext-Regular"
        default: return "AvenirNext-Regular"
        }
    }

    // MARK: - Motion

    static let reveal = Animation.easeOut(duration: 0.55)
    static let softSpring = Animation.spring(response: 0.45, dampingFraction: 0.86)
}

// MARK: - View helpers

struct AtmosphereBackground: View {
    var dark: Bool = false

    var body: some View {
        Group {
            if dark {
                BrandTheme.heroWash
            } else {
                BrandTheme.atmosphere
            }
        }
        .ignoresSafeArea()
    }
}

/// Full-bleed homepage hero with brand wash — used on splash / home.
struct HeroBackground: View {
    var imageName: String = "HomeHero"
    var intensity: Double = 1.0

    var body: some View {
        ZStack {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()

            BrandTheme.heroWash
                .opacity(0.88 * intensity)
        }
        .ignoresSafeArea()
    }
}
