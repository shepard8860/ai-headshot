import XCTest
@testable import AIHeadshot

final class TemplateTests: XCTestCase {
    func testTemplateDecoding() throws {
        let json = """
        {
            "template_id": "tpl-001",
            "name": "商务正装",
            "category": "正式",
            "thumbnail_url": "https://cdn.example.com/tpl001.jpg",
            "description": "适合求职简历的商务正装照",
            "price": 9.9,
            "is_premium": true
        }
        """
        let decoder = JSONDecoder()
        let template = try decoder.decode(Template.self, from: try XCTUnwrap(json.data(using: .utf8)))
        XCTAssertEqual(template.id, "tpl-001")
        XCTAssertEqual(template.name, "商务正装")
        XCTAssertEqual(template.category, "正式")
        XCTAssertEqual(template.thumbnailURL, "https://cdn.example.com/tpl001.jpg")
        XCTAssertEqual(template.price, 9.9)
        XCTAssertTrue(template.isPremium)
    }

    func testTemplateDecodingWithoutPrice() throws {
        let json = """
        {
            "template_id": "tpl-002",
            "name": "创意风格",
            "category": "个性",
            "thumbnail_url": "https://cdn.example.com/tpl002.jpg",
            "description": "创意风格照",
            "is_premium": false
        }
        """
        let decoder = JSONDecoder()
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
