import SwiftUI

@main
struct iDEApp: App {
    @AppStorage("ide.onboarding.complete") private var onboardingComplete = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if onboardingComplete {
                    ContentView()
                } else {
                    OnboardingView {
                        onboardingComplete = true
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
