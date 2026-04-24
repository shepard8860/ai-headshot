import Foundation

enum Constants {
    static let baseURL: URL = {
        guard let url = URL(string: "https://api.ai-headshot.app") else {
            fatalError("Invalid base URL")
        }
        return url
    }()
    static let appGroupID = "group.com.ai-headshot.app"
    static let productID = "com.ai-headshot.hd_unlock"

    enum API {
        static let generate = "/api/generate"
        static func orderStatus(orderID: String) -> String { "/api/order/\(orderID)/status" }
        static func verifyPayment(orderID: String) -> String { "/api/order/\(orderID)/verify-payment" }
        static let templates = "/api/templates"
    }

    enum OrderStatus: String, Codable {
        case pending = "PENDING"
        case generating = "GENERATING"
        case completed = "COMPLETED"
        case failed = "FAILED"
        case paid = "PAID"
    }
}
