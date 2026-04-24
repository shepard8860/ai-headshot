import XCTest
@testable import AIHeadshot

final class TemplateTests: XCTestCase {
    func testTemplateDecoding() throws {
        let json = """
        {
            "template_id": "tpl-001",
            "name": "\u5546\u52a1\u6b63\u88c5",
            "category": "\u6b63\u5f0f",
            "thumbnail_url": "https://cdn.example.com/tpl001.jpg",
            "description": "\u9002\u5408\u6c42\u804c\u7b80\u5386\u7684\u5546\u52a1\u6b63\u88c5\u7167",
            "price": 9.9,
            "is_premium": true
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let template = try decoder.decode(Template.self, from: try XCTUnwrap(json.data(using: .utf8)))
        XCTAssertEqual(template.id, "tpl-001")
        XCTAssertEqual(template.name, "\u5546\u52a1\u6b63\u88c5")
        XCTAssertEqual(template.category, "\u6b63\u5f0f")
        XCTAssertEqual(template.thumbnailURL, "https://cdn.example.com/tpl001.jpg")
        XCTAssertEqual(template.price, 9.9)
        XCTAssertTrue(template.isPremium)
    }

    func testTemplateDecodingWithoutPrice() throws {
        let json = """
        {
            "template_id": "tpl-002",
            "name": "\u521b\u610f\u98ce\u683c",
            "category": "\u4e2a\u6027",
            "thumbnail_url": "https://cdn.example.com/tpl002.jpg",
            "description": "\u521b\u610f\u98ce\u683c\u7167",
            "is_premium": false
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let template = try decoder.decode(Template.self, from: try XCTUnwrap(json.data(using: .utf8)))
        XCTAssertNil(template.price)
        XCTAssertFalse(template.isPremium)
    }

    func testTemplateEquality() {
        let t1 = Template(id: "1", name: "A", category: "C", thumbnailURL: "", description: "", price: nil, isPremium: false)
        let t2 = Template(id: "1", name: "A", category: "C", thumbnailURL: "", description: "", price: nil, isPremium: false)
        let t3 = Template(id: "2", name: "A", category: "C", thumbnailURL: "", description: "", price: nil, isPremium: false)
        XCTAssertEqual(t1, t2)
        XCTAssertNotEqual(t1, t3)
    }

    func testTemplateHashable() {
        let t1 = Template(id: "1", name: "A", category: "C", thumbnailURL: "", description: "", price: nil, isPremium: false)
        let t2 = Template(id: "1", name: "A", category: "C", thumbnailURL: "", description: "", price: nil, isPremium: false)
        var set = Set<Template>()
        set.insert(t1)
        set.insert(t2)
        XCTAssertEqual(set.count, 1)
    }

    func testTemplateCategory() {
        let templates = [
            Template(id: "1", name: "A", category: "C", thumbnailURL: "", description: "", price: nil, isPremium: false),
            Template(id: "2", name: "B", category: "C", thumbnailURL: "", description: "", price: nil, isPremium: true)
        ]
        let category = TemplateCategory(name: "C", templates: templates)
        XCTAssertEqual(category.templates.count, 2)
    }
}
