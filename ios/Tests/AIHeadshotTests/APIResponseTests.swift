import XCTest
@testable import AIHeadshot

final class APIResponseTests: XCTestCase {
    func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(type, from: json.data(using: .utf8)!)
    }

    func testAPIErrorResponseDecoding() throws {
        let json = """
        {"error": "Invalid request", "code": "INVALID_REQUEST", "details": "Missing field"}
        """
        let error = try decode(APIErrorResponse.self, from: json)
        XCTAssertEqual(error.code, "INVALID_REQUEST")
        XCTAssertEqual(error.message, "Invalid request")
        XCTAssertEqual(error.details, "Missing field")
    }

    func testSSEProgressEventDecoding() throws {
        let json = """
        {"progress": 75, "status": "GENERATING", "message": "Processing hair", "preview_urls": ["https://example.com/img.jpg"], "error_message": null}
        """
        let event = try decode(SSEProgressEvent.self, from: json)
        XCTAssertEqual(event.progress, 75)
        XCTAssertEqual(event.status, "GENERATING")
        XCTAssertEqual(event.message, "Processing hair")
        XCTAssertEqual(event.previewUrls?.first, "https://example.com/img.jpg")
    }

    func testTemplateListResponseDecoding() throws {
        let json = """
        {
            "total": 1,
            "templates": [
                {"template_id": "t1", "name": "Business", "category": "Formal", "thumbnail_url": "https://example.com/t1.jpg", "description": "Professional", "price": 9.9, "is_premium": true}
            ]
        }
        """
        let response = try decode(TemplateListResponse.self, from: json)
        XCTAssertEqual(response.total, 1)
        XCTAssertEqual(response.templates.count, 1)
        XCTAssertEqual(response.templates.first?.name, "Business")
        XCTAssertTrue(response.templates.first?.isPremium == true)
    }

    func testVerifyPaymentResponseDecoding() throws {
        let json = """
        {"success": true, "hd_urls": ["https://example.com/hd.jpg"], "message": "Payment verified"}
        """
        let response = try decode(VerifyPaymentResponse.self, from: json)
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.hdUrls?.first, "https://example.com/hd.jpg")
        XCTAssertEqual(response.message, "Payment verified")
    }

    func testPresignedURLResponseDecoding() throws {
        let json = """
        {"url": "https://s3.example.com/upload", "key": "images/123.jpg"}
        """
        let response = try decode(PresignedURLResponse.self, from: json)
        XCTAssertEqual(response.url, "https://s3.example.com/upload")
        XCTAssertEqual(response.key, "images/123.jpg")
    }

    func testOrderCreateResponseDecoding() throws {
        let json = """
        {"order_id": "ord-abc-123", "status": "PENDING", "estimated_seconds": 30}
        """
        let response = try decode(OrderCreateResponse.self, from: json)
        XCTAssertEqual(response.orderID, "ord-abc-123")
        XCTAssertEqual(response.status, .pending)
        XCTAssertEqual(response.estimatedSeconds, 30)
    }
}
