import Foundation

struct Order: Identifiable, Codable, Equatable {
    let id: String
    let templateID: String
    let status: Constants.OrderStatus
    let imageURL: String?
    let createdAt: Date
    let updatedAt: Date
    var paid: Bool

    enum CodingKeys: String, CodingKey {
        case id = "order_id"
        case templateID = "template_id"
        case status
        case imageURL = "original_image_url"
        case createdAt
        case updatedAt
    }

    init(id: String, templateID: String, status: Constants.OrderStatus, imageURL: String?, createdAt: Date, updatedAt: Date, paid: Bool) {
        self.id = id
        self.templateID = templateID
        self.status = status
        self.imageURL = imageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.paid = paid
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        templateID = try container.decode(String.self, forKey: .templateID)
        status = try container.decode(Constants.OrderStatus.self, forKey: .status)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        paid = (status == .paid)
    }
}

struct OrderCreateRequest: Codable {
    let userID: String
    let templateID: String
    let originalImageURL: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case templateID = "template_id"
        case originalImageURL = "original_image_url"
    }
}

struct OrderCreateResponse: Codable {
    let orderID: String
    let status: Constants.OrderStatus
    let estimatedSeconds: Int

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case status
        case estimatedSeconds = "estimated_seconds"
    }
}
