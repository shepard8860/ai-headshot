import Foundation
import UIKit
import Vision

actor FaceDetectionService {
    static let shared = FaceDetectionService()

    func analyze(image: UIImage) async throws -> FaceQualityResult {
        guard let cgImage = image.cgImage else {
            throw FaceError.invalidImage
        }

        let request = VNDetectFaceLandmarksRequest()
        request.constellation = .constellation76Points
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let results = request.results as? [VNFaceObservation], let face = results.first else {
            var noFace = FaceQualityResult()
            noFace.message = "未检测到人脸，请将脸部放入框内"
            return noFace
        }

        var result = FaceQualityResult()
        result.confidence = face.confidence

        // Check frontal pose (yaw and roll should be near zero)
        if let yaw = face.yaw?.doubleValue, let roll = face.roll?.doubleValue {
            result.isFrontal = abs(yaw) < 0.3 && abs(roll) < 0.3
        } else {
            result.isFrontal = true
        }

        // Check lighting (confidence proxy)
        result.goodLighting = face.confidence > 0.7

        // Check occlusion using landmarks presence
        if let landmarks = face.landmarks {
            result.noOcclusion = landmarks.allPoints != nil && landmarks.faceContour != nil
        } else {
            result.noOcclusion = false
        }

        // Check resolution
        let minSize: CGFloat = 512
        result.sufficientResolution = image.size.width >= minSize && image.size.height >= minSize

        result.message = result.isAllPassed ? "人脸质量检测通过" : result.failedReasons.joined(separator: "\n")
        return result
    }

    func cropAndNormalize(image: UIImage, faceObservation: VNFaceObservation) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let boundingBox = faceObservation.boundingBox
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let rect = CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
        // Expand slightly for context
        let expanded = rect.insetBy(dx: -rect.width * 0.2, dy: -rect.height * 0.3)
        let safeRect = expanded.intersection(CGRect(origin: .zero, size: imageSize))
        guard let cropped = cgImage.cropping(to: safeRect) else { return nil }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }

    enum FaceError: Error {
        case invalidImage
    }
}
