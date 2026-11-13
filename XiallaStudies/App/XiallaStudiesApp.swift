import SwiftUI

@main
struct XiallaStudiesApp: App {
    @StateObject private var session = StudySession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .tint(BrandTheme.accent)
                .task {
                    await session.bootstrap()
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var session: StudySession
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if session.isLoading {
                ZStack {
                    HeroBackground()
                    ProgressView()
                        .tint(BrandTheme.chalk)
                }
            } else if showSplash && !session.hasSeenSplash {
                SplashView {
                    Task { await session.markSplashSeen() }
                    withAnimation(BrandTheme.reveal) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
            } else {
                NavigationStack(path: $session.path) {
                    HomeView()
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .eligibility:
                                EligibilityView()
                            case .consent:
                                ConsentFlowView()
                            case .baselineSurveys:
                                SurveyFlowView(timepoint: .baseline)
                            case .week4FollowUp:
                                SurveyFlowView(timepoint: .week4)
                            case .reminders:
                                ReminderSettingsView()
                            case .kitStub:
                                KitFulfillmentStubView()
                            case .provider:
                                ProviderProfileView()
                            }
                        }
                }
                .sheet(isPresented: $session.showSettings) {
                    SettingsView()
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(BrandTheme.reveal, value: showSplash)
        .animation(BrandTheme.reveal, value: session.isLoading)
        .onChange(of: session.hasSeenSplash) { _, seen in
            if seen { showSplash = false }
        }
    }
}
