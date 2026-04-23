import SwiftUI

@main
struct AIHeadshotApp: App {
    @State private var showLaunchScreen = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .opacity(showLaunchScreen ? 0 : 1)

                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    showLaunchScreen = false
                                }
                            }
                        }
                }
            }
        }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    let userID: String = {
        if let stored = UserDefaults.standard.string(forKey: "ai_headshot_user_id") {
            return stored
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: "ai_headshot_user_id")
        return newID
    }()

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(userID: userID)
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(0)

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(1)
        }
    }
}
