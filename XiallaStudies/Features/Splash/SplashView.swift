import SwiftUI

/// Brand-first welcome — one composition: wordmark, one line, one CTA.
struct SplashView: View {
    var onContinue: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            AtmosphereBackground(dark: true)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 18) {
                    BrandWordmark(size: 48, light: true)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)

                    Text("A discreet observational study of Xialla.")
                        .font(BrandTheme.body(17))
                        .foregroundStyle(BrandTheme.parchment.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)
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
