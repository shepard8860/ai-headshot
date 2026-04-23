import Foundation

struct Template: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let category: String
    let thumbnailURL: String
    let description: String?
    let price: Double?
    let isPremium: Bool

    enum CodingKeys: String, CodingKey {
        case id = "template_id"
        case name
        case category
        case thumbnailURL = "thumbnail_url"
        case description
        case price
        case isPremium = "is_premium"
    }
}

struct TemplateCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let templates: [Template]
}
