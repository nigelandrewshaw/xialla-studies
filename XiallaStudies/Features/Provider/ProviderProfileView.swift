import SwiftUI

/// Branded investigator profile driven by `StudyConfig.provider` (Jeff hardcode for demo).
struct ProviderProfileView: View {
    var provider: StudyProviderParameters = StudyConfig.provider
    @State private var appeared = false

    var body: some View {
        ZStack {
            AtmosphereBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    portrait

                    VStack(alignment: .leading, spacing: 8) {
                        Text(provider.displayName)
                            .font(BrandTheme.display(28, weight: .medium))
                            .foregroundStyle(BrandTheme.ink)
                        Text(provider.credentials)
                            .font(BrandTheme.body(15, weight: .semibold))
                            .foregroundStyle(BrandTheme.tan)
                        Text(provider.title)
                            .font(BrandTheme.body(16))
                            .foregroundStyle(BrandTheme.ink)
                        Text(provider.specialty)
                            .font(BrandTheme.body(15))
                            .foregroundStyle(BrandTheme.graphite)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)

                    VStack(alignment: .leading, spacing: 6) {
                        labelRow("Site", provider.organization)
                        labelRow("Location", provider.location)
                        labelRow("Study / site codes", "\(StudyConfig.studyCode) · \(StudyConfig.siteCode)")
                    }

                    Text(provider.bio)
                        .font(BrandTheme.body(15))
                        .foregroundStyle(BrandTheme.graphite)
                        .fixedSize(horizontal: false, vertical: true)

                    if let url = provider.profileURL {
                        Link(destination: url) {
                            Text("View on xialla.com")
                                .font(BrandTheme.body(15, weight: .semibold))
                                .foregroundStyle(BrandTheme.ink)
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(24)
            }
        }
        .navigationTitle("Study investigator")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(BrandTheme.reveal) {
                appeared = true
            }
        }
    }

    @ViewBuilder
    private var portrait: some View {
        Group {
            if let asset = provider.photoAssetName {
                Image(asset)
                    .resizable()
                    .scaledToFill()
            } else {
                BrandTheme.tan.opacity(0.45)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
        .clipped()
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [.clear, BrandTheme.ink.opacity(0.35)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 1.02)
    }

    private func labelRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(BrandTheme.body(11, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(BrandTheme.tan)
            Text(value)
                .font(BrandTheme.body(15))
                .foregroundStyle(BrandTheme.ink)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ProviderProfileView()
    }
}
