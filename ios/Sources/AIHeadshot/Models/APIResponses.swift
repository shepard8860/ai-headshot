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
}

struct PresignedURLResponse: Codable {
    let url: String
    let key: String
}
