import SwiftUI

struct LaunchScreenView: View {
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.crop.rectangle.stack.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(scale)

                VStack(spacing: 8) {
                    Text("AI职业照")
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary)

                    Text("轻量AI职业形象照")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .opacity(opacity)

                Spacer()

                Text(" powered by AI ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 32)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1.0
                scale = 1.0
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
