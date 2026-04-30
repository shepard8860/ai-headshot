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
                        .task {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            withAnimation(.easeOut(duration: 0.5)) {
                                showLaunchScreen = false
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
        if let stored = UserDefaults.standard.string(forKey: Constants.userDefaultsUserIDKey) {
            return stored
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: Constants.userDefaultsUserIDKey)
        return newID
    }()

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0:
                    HomeView(userID: userID)
                case 1:
                    ProfileView()
                default:
                    HomeView(userID: userID)
                }
            }

            customTabBar
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            TabBarButton(
                title: "首页",
                icon: "house.fill",
                isSelected: selectedTab == 0
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 0
                }
            }

            TabBarButton(
                title: "我的",
                icon: "person.fill",
                isSelected: selectedTab == 1
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 1
                }
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: -4)
        )
        .padding(.horizontal, 40)
        .padding(.bottom, 12)
    }
}

struct TabBarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? Color(red: 0.35, green: 0.25, blue: 0.65) : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }
}
