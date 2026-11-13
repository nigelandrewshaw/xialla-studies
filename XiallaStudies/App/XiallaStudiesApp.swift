import SwiftUI

@main
struct XiallaStudiesApp: App {
    @StateObject private var session = StudySession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
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
            if showSplash || session.isLoading {
                SplashView {
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
    }
}
