import SwiftUI

struct BrandWordmark: View {
    var size: CGFloat = 36
    var light: Bool = false
    /// Prefer the official logo asset; fall back to typographic wordmark.
    var useLogoAsset: Bool = true

    var body: some View {
        Group {
            if useLogoAsset {
                Image(light ? "XiallaLogoWhite" : "XiallaLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: size * 0.85)
                    .accessibilityLabel("Xialla")
            } else {
                Text("Xialla")
                    .font(BrandTheme.display(size, weight: .medium))
                    .tracking(1.2)
                    .foregroundStyle(light ? BrandTheme.chalk : BrandTheme.ink)
            }
        }
        .accessibilityAddTraits(.isHeader)
    }
}

struct PrimaryButton: View {
    let title: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BrandTheme.body(17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(BrandTheme.chalk)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(enabled ? BrandTheme.ink : BrandTheme.graphite.opacity(0.35))
                )
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BrandTheme.body(16, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(BrandTheme.ink)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(BrandTheme.ink.opacity(0.55), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct SectionIntro: View {
    let headline: String
    let support: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(headline)
                .font(BrandTheme.display(28, weight: .medium))
                .foregroundStyle(BrandTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(support)
                .font(BrandTheme.body(16))
                .foregroundStyle(BrandTheme.graphite)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatusChip: View {
    let text: String
    var tone: Tone = .neutral

    enum Tone {
        case neutral, active, due, done

        var color: Color {
            switch self {
            case .neutral: return BrandTheme.graphite
            case .active: return BrandTheme.tan
            case .due: return BrandTheme.attention
            case .done: return BrandTheme.ink
            }
        }
    }

    var body: some View {
        Text(text)
            .font(BrandTheme.body(13, weight: .medium))
            .foregroundStyle(tone.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(tone.color.opacity(0.14))
            )
    }
}
