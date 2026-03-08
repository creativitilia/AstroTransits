import SwiftUI

@main
struct AstroTransitsApp: App {
    
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            if appViewModel.isOnboarded {
                // We'll build this in Step 6
                Text("Home screen coming soon")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
            } else {
                OnboardingView(appViewModel: appViewModel)
            }
        }
    }
}
