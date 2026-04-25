import Foundation

struct APIErrorResponse: Codable, Error {
    let error: String
    let code: String
    let details: String?

    var message: String { error }
}

struct SSEProgressEvent: Codable {
    let progress: Double
    let status: String
    let message: String?
    let previewUrls: [String]?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case progress
        case status
        case message
        case previewUrls = "preview_urls"
        case errorMessage = "error_message"
    }
}

struct TemplateListResponse: Codable {
    let total: Int
    let templates: [Template]
}

struct VerifyPaymentRequest: Codable {
    let receiptData: String

    enum CodingKeys: String, CodingKey {
        case receiptData = "receipt_data"
    }
}

struct VerifyPaymentResponse: Codable {
    let success: Bool
    let hdUrls: [String]?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case success
        case hdUrls = "hd_urls"
        case message
    }
}

struct PresignedURLResponse: Codable {
    let url: String
    let key: String
}
