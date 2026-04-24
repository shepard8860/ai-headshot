import Foundation
import SwiftUI
import AVFoundation
import Vision
import UIKit

@MainActor
final class CameraViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var faceQuality: FaceQualityResult?
    @Published var isAnalyzing = false
    @Published var isUploading = false
    @Published var uploadURL: String?
    @Published var errorMessage: String?
    @Published var showCamera = false

    let session = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    func setupSession(previewView: CameraPreviewView) async {
        session.beginConfiguration()
        session.sessionPreset = .photo
        defer { session.commitConfiguration() }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            errorMessage = "无法访问前置摄像头"
            return
        }
        session.addInput(input)

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        previewView.videoPreviewLayer = layer
    }

    func startSession() {
        let captureSession = session
        DispatchQueue.global(qos: .userInitiated).async {
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
        }
    }

    func stopSession() {
        let captureSession = session
        DispatchQueue.global(qos: .userInitiated).async {
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureDelegate(viewModel: self))
    }

    func analyzeCapturedImage() async {
        guard let image = capturedImage else { return }
        isAnalyzing = true
        do {
            let result = try await FaceDetectionService.shared.analyze(image: image)
            faceQuality = result
        } catch {
            errorMessage = "人脸检测失败: \(error.localizedDescription)"
        }
        isAnalyzing = false
    }

    func uploadImage() async {
        guard let image = capturedImage else { return }
        isUploading = true
        do {
            let url = try await UploadService.shared.uploadImage(image)
            uploadURL = url
        } catch {
            errorMessage = "上传失败: \(error.localizedDescription)"
        }
        isUploading = false
    }
}

// MARK: - PhotoCaptureDelegate
final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    weak var viewModel: CameraViewModel?

    init(viewModel: CameraViewModel) {
        self.viewModel = viewModel
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            Task { @MainActor in
                viewModel?.errorMessage = "拍照失败: \(error.localizedDescription)"
            }
            return
        }
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        Task { @MainActor in
            viewModel?.capturedImage = image
            viewModel?.showCamera = false
            await viewModel?.analyzeCapturedImage()
        }
    }
}

// MARK: - CameraPreviewView (UIKit bridge)
final class CameraPreviewView: UIView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer? {
        didSet {
            oldValue?.removeFromSuperlayer()
            if let layer = videoPreviewLayer {
                layer.frame = bounds
                layer.videoGravity = .resizeAspectFill
                self.layer.addSublayer(layer)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer?.frame = bounds
    }
}
