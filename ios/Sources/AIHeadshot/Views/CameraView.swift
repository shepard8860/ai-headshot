import SwiftUI
import AVFoundation

struct CameraView: View {
    let template: Template
    let userID: String
    @StateObject private var viewModel = CameraViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showUpload = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.showCamera {
                    cameraPreview
                } else if let image = viewModel.capturedImage {
                    capturedImagePreview(image: image)
                }
            }
            .navigationTitle("拍摄证件照")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .onAppear {
                viewModel.showCamera = true
            }
            .sheet(isPresented: $showUpload) {
                if let url = viewModel.uploadURL {
                    UploadView(template: template, imageURL: url, userID: userID)
                }
            }
            .navigationDestination(isPresented: .constant(false)) {
                EmptyView()
            }
        }
    }

    private var cameraPreview: some View {
        ZStack {
            CameraPreviewRepresentable(viewModel: viewModel)
                .ignoresSafeArea()

            VStack {
                Spacer()
                faceGuideOverlay
                Spacer()
                captureButton
                    .padding(.bottom, 40)
            }
        }
    }

    private var faceGuideOverlay: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(Color.white.opacity(0.8), lineWidth: 2)
            .frame(width: 260, height: 320)
            .overlay(
                VStack {
                    Text("将脸部放入框内")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                    Spacer()
                }
                .padding(8)
            )
    }

    private var captureButton: some View {
        Button(action: {
            viewModel.capturePhoto()
        }) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 72, height: 72)
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 80, height: 80)
            }
        }
    }

    private func capturedImagePreview(image: UIImage) -> some View {
        VStack(spacing: 20) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 400)
                .cornerRadius(12)

            if viewModel.isAnalyzing {
                ProgressView("检测人脸质量中...")
            } else if let quality = viewModel.faceQuality {
                qualityStatusView(quality: quality)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            HStack(spacing: 20) {
                Button("重拍") {
                    viewModel.capturedImage = nil
                    viewModel.faceQuality = nil
                    viewModel.showCamera = true
                }
                .buttonStyle(.bordered)

                if viewModel.isUploading {
                    ProgressView("上传中...")
                } else if viewModel.faceQuality?.isAllPassed == true {
                    Button("上传并生成") {
                        Task {
                            await viewModel.uploadImage()
                            if viewModel.uploadURL != nil {
                                showUpload = true
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }

    private func qualityStatusView(quality: FaceQualityResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: quality.isAllPassed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                Text(quality.message)
                    .font(.subheadline)
            }
            .foregroundColor(quality.isAllPassed ? .green : .orange)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - UIViewRepresentable for Camera Preview
struct CameraPreviewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: CameraViewModel

    func makeUIView(context: Context) -> CameraPreviewView {
        let previewView = CameraPreviewView()
        Task {
            await viewModel.setupSession(previewView: previewView)
            viewModel.startSession()
        }
        return previewView
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}

    static func dismantleUIView(_ uiView: CameraPreviewView, coordinator: ()) {
        // Session cleanup handled in viewModel
    }
}
