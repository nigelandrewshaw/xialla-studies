import SwiftUI

/// Brand-first welcome — full-bleed homepage hero, wordmark, one line, one CTA.
struct SplashView: View {
    var onContinue: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            HeroBackground()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    BrandWordmark(size: 52, light: true)
                        .padding(.horizontal, 48)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .scaleEffect(appeared ? 1 : 0.96)

                    Text("A discreet observational study of Xialla.")
                        .font(BrandTheme.body(17))
                        .foregroundStyle(BrandTheme.chalk.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                }

                Spacer()

                PrimaryButton(title: "Continue") {
                    onContinue()
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(BrandTheme.softSpring) {
                appeared = true
            }
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    SplashView(onContinue: {})
}
