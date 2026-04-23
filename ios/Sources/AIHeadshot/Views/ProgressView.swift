import SwiftUI

struct GenerationProgressView: View {
    let orderID: String
    @ObservedObject var viewModel: GenerateViewModel
    @State private var showResult = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 180, height: 180)

                Circle()
                    .trim(from: 0, to: CGFloat(min(viewModel.progress, 1.0)))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .purple, .pink]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.progress)

                VStack {
                    Text("\(Int(viewModel.progress * 100))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if viewModel.orderStatus == .failed {
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                Text("生成失败，请重试")
                    .foregroundColor(.red)
            }

            if let error = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.orange)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("生成中...")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.orderStatus) { newStatus in
            if newStatus == .completed {
                showResult = true
            }
        }
        .navigationDestination(isPresented: $showResult) {
            ResultView(orderID: orderID)
        }
    }
}
