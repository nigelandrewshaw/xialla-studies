import SwiftUI

/// Branded investigator profile driven by `StudyConfig.provider` (Jeff hardcode for demo).
struct ProviderProfileView: View {
    var provider: StudyProviderParameters = StudyConfig.provider
    @State private var appeared = false

    var body: some View {
        ZStack {
            AtmosphereBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    portrait

                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(provider.displayName)
                                .font(BrandTheme.display(28, weight: .medium))
                                .foregroundStyle(BrandTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(provider.credentials)
                                .font(BrandTheme.body(15, weight: .semibold))
                                .foregroundStyle(BrandTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(provider.title)
                                .font(BrandTheme.body(16))
                                .foregroundStyle(BrandTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(provider.specialty)
                                .font(BrandTheme.body(15))
                                .foregroundStyle(BrandTheme.graphite)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)

                        VStack(alignment: .leading, spacing: 10) {
                            labelRow("Site", provider.organization)
                            labelRow("Location", provider.location)
                            labelRow("Study code", StudyConfig.studyCode)
                            labelRow("Site code", StudyConfig.siteCode)
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
                    .padding(.horizontal, BrandTheme.contentInset)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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

    /// Full-bleed portrait constrained like Home hero — avoids scaledToFill overflow clipping text.
    @ViewBuilder
    private var portrait: some View {
        Color.clear
            .frame(height: 320)
            .frame(maxWidth: .infinity)
            .overlay {
                GeometryReader { geo in
                    Group {
                        if let asset = provider.photoAssetName {
                            Image(asset)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        } else {
                            BrandTheme.mist
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        LinearGradient(
                            colors: [.clear, BrandTheme.ink.opacity(0.28)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    }
                }
            }
            .clipped()
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 1.02)
    }

    private func labelRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(BrandTheme.body(11, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(BrandTheme.graphite)
            Text(value)
                .font(BrandTheme.body(15, weight: .medium))
                .foregroundStyle(BrandTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        ProviderProfileView()
    }
}
