import Foundation
import UIKit

actor UploadService {
    static let shared = UploadService()
    private let session = URLSession.shared

    /// Request presigned URL from backend and upload image data.
    func uploadImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw UploadError.invalidImage
        }
        let presigned = try await fetchPresignedURL()
        guard let uploadURL = URL(string: presigned.url) else {
            throw UploadError.invalidURL
        }
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await session.upload(for: request, from: imageData)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw UploadError.uploadFailed
        }
        return presigned.key
    }

    private func fetchPresignedURL() async throws -> PresignedURLResponse {
        var request = URLRequest(url: Constants.baseURL.appendingPathComponent("api/upload/presign"))
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw UploadError.presignFailed
        }
        return try JSONDecoder().decode(PresignedURLResponse.self, from: data)
    }

    enum UploadError: Error {
        case invalidImage
        case invalidURL
        case uploadFailed
        case presignFailed
    }
}
