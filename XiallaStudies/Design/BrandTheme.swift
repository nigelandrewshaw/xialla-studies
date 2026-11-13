import SwiftUI

/// Xialla study visual tokens — official Pantone brand swatch + site layout habits.
/// Fieldwork (Adobe Fonts / Typekit) cannot be legally redistributed as an app binary;
/// we match weights with Avenir Next until a desktop Fieldwork license is added under
/// `Resources/Fonts/` + `UIAppFonts`. See `docs/BUILD_NOTES.md`.
enum BrandTheme {
    // MARK: - Official swatch (Pantone)

    /// Near-black — Pantone 419 C `#212322`. Primary text / primary buttons / dark chrome.
    static let ink = Color(red: 33 / 255, green: 35 / 255, blue: 34 / 255)

    /// Tan — Pantone 4665 C `#CDA788`. Visual interest only (slider fills, light accents) — not full-screen fills.
    static let tan = Color(red: 205 / 255, green: 167 / 255, blue: 136 / 255)

    /// Accent — Pantone 1645 C `#FF6A39`. Available sparingly for badges; not primary CTAs or slider tracks.
    static let accent = Color(red: 255 / 255, green: 106 / 255, blue: 57 / 255)

    /// Forest — Pantone kit `#1D3C34`. Available sparingly; not brand chrome.
    static let forest = Color(red: 29 / 255, green: 60 / 255, blue: 52 / 255)

    /// Sage — Pantone kit `#A9C47F`. Available sparingly; not brand chrome.
    static let sage = Color(red: 169 / 255, green: 196 / 255, blue: 127 / 255)

    // MARK: - Derived UI tokens

    /// Secondary text on white.
    static let graphite = Color(red: 72 / 255, green: 68 / 255, blue: 64 / 255)

    /// Soft border / chip wash — light tan tint on white.
    static let mist = Color(red: 232 / 255, green: 214 / 255, blue: 196 / 255)

    /// Light surface wash (chips, subtle bands) — not a screen fill.
    static let parchment = mist

    /// Reminders / due — ink family for clarity on white.
    static let attention = ink

    /// Pure white — main screen backgrounds and text on dark fills.
    static let chalk = Color.white

    /// Main screen canvas.
    static let canvas = Color.white

    // MARK: - Gradients

    /// Subtle top wash for main screens — white with a light tan tip for interest (not a full tan fill).
    static var atmosphere: LinearGradient {
        LinearGradient(
            colors: [
                mist.opacity(0.55),
                canvas,
                canvas
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var heroWash: LinearGradient {
        LinearGradient(
            colors: [
                ink.opacity(0.35),
                ink.opacity(0.62),
                Color.black.opacity(0.78)
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

    // MARK: - Layout

    /// Horizontal content inset — keeps Dynamic Island / narrow phones from clipping leading edges.
    static let contentInset: CGFloat = 24

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
        GeometryReader { geo in
            ZStack {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                BrandTheme.heroWash
                    .opacity(0.88 * intensity)
            }
        }
        .ignoresSafeArea()
    }
}
