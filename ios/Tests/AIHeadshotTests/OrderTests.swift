import XCTest
@testable import AIHeadshot

final class OrderTests: XCTestCase {
    func testOrderStatusRawValues() {
        XCTAssertEqual(Constants.OrderStatus.pending.rawValue, "PENDING")
        XCTAssertEqual(Constants.OrderStatus.generating.rawValue, "GENERATING")
        XCTAssertEqual(Constants.OrderStatus.completed.rawValue, "COMPLETED")
        XCTAssertEqual(Constants.OrderStatus.failed.rawValue, "FAILED")
        XCTAssertEqual(Constants.OrderStatus.paid.rawValue, "PAID")
    }

    func testOrderStatusDecoding() throws {
        let json = "\"COMPLETED\""
        let data = try XCTUnwrap(json.data(using: .utf8))
        let status = try JSONDecoder().decode(Constants.OrderStatus.self, from: data)
        XCTAssertEqual(status, .completed)
    }

    func testOrderDecoding() throws {
        let json = """
        {
            "order_id": "ord-123",
            "template_id": "tpl-business",
            "status": "COMPLETED",
            "original_image_url": "https://example.com/image.jpg",
            "createdAt": "2024-01-15T08:30:00Z",
            "updatedAt": "2024-01-15T08:35:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let orderData = try XCTUnwrap(json.data(using: .utf8))
        let order = try decoder.decode(Order.self, from: orderData)
        XCTAssertEqual(order.id, "ord-123")
        XCTAssertEqual(order.templateID, "tpl-business")
        XCTAssertEqual(order.status, .completed)
        XCTAssertEqual(order.imageURL, "https://example.com/image.jpg")
        XCTAssertTrue(order.paid)
    }

    func testOrderCreateRequestEncoding() throws {
        let request = OrderCreateRequest(userID: "user-1", templateID: "tpl-1", originalImageURL: "https://example.com/img.jpg")
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let dict = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
        XCTAssertEqual(dict["user_id"], "user-1")
        XCTAssertEqual(dict["template_id"], "tpl-1")
        XCTAssertEqual(dict["original_image_url"], "https://example.com/img.jpg")
    }

    func testOrderEquality() {
        let now = Date()
        let o1 = Order(id: "1", templateID: "a", status: .pending, imageURL: nil, createdAt: now, updatedAt: now, paid: false)
        let o2 = Order(id: "1", templateID: "a", status: .pending, imageURL: nil, createdAt: now, updatedAt: now, paid: false)
        XCTAssertEqual(o1, o2)
    }
}
