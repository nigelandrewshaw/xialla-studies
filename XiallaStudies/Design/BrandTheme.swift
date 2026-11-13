import SwiftUI

/// Xialla study visual tokens — discreet, adult, product-led (not clinical chrome).
/// Avoids generic medical blue and common AI-default purple / cream / terracotta looks.
enum BrandTheme {
    // MARK: - Colors

    /// Deep ink charcoal — primary surfaces / wordmark weight.
    static let ink = Color(red: 0.09, green: 0.11, blue: 0.13)

    /// Soft graphite for secondary text.
    static let graphite = Color(red: 0.35, green: 0.38, blue: 0.40)

    /// Warm parchment atmosphere (not flat clinical white).
    static let parchment = Color(red: 0.96, green: 0.95, blue: 0.93)

    /// Mist for gradients / secondary surfaces.
    static let mist = Color(red: 0.90, green: 0.92, blue: 0.93)

    /// Deep sea-teal accent — calm confidence, not hospital blue.
    static let teal = Color(red: 0.12, green: 0.38, blue: 0.40)

    /// Soft teal highlight for focus / progress.
    static let tealSoft = Color(red: 0.22, green: 0.55, blue: 0.56)

    /// Attention (reminders / AE) — restrained amber, not alarm red by default.
    static let attention = Color(red: 0.72, green: 0.45, blue: 0.18)

    /// Success / completion.
    static let success = Color(red: 0.22, green: 0.48, blue: 0.36)

    // MARK: - Gradients

    static var atmosphere: LinearGradient {
        LinearGradient(
            colors: [
                parchment,
                mist.opacity(0.85),
                teal.opacity(0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var heroWash: LinearGradient {
        LinearGradient(
            colors: [
                ink,
                Color(red: 0.12, green: 0.22, blue: 0.26),
                teal.opacity(0.55)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Typography

    /// Display / brand face — distinctive serif for wordmark & heroes.
    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Body / UI face — rounded humanist feel without Inter/Roboto defaults.
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
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
