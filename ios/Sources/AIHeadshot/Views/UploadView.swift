import SwiftUI

struct UploadView: View {
    let template: Template
    let imageURL: String
    let userID: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var generateVM = GenerateViewModel()
    @State private var navigateToProgress = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "arrow.up.doc.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("图片已上传成功")
                    .font(.title2.bold())

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("模板:")
                            .foregroundColor(.secondary)
                        Text(template.name)
                    }
                    HStack {
                        Text("图片:")
                            .foregroundColor(.secondary)
                        Text(imageURL)
                            .lineLimit(1)
                    }
                }
                .font(.subheadline)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                if generateVM.isLoading {
                    ProgressView()
                    Text(generateVM.statusMessage)
                        .foregroundColor(.secondary)
                }

                if let error = generateVM.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }

                Button("开始生成") {
                    Task {
                        await generateVM.startGeneration(userID: userID, templateID: template.id, imageURL: imageURL)
                        navigateToProgress = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(generateVM.isLoading)

                Spacer()
            }
            .padding()
            .navigationTitle("确认上传")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToProgress) {
                GenerationProgressView(orderID: generateVM.orderID, viewModel: generateVM)
            }
        }
    }
}
