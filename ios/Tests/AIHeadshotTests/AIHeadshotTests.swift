import XCTest
@testable import AIHeadshot

final class AIHeadshotTests: XCTestCase {
    func testOrderStatusRawValues() {
        XCTAssertEqual(Constants.OrderStatus.pending.rawValue, "PENDING")
        XCTAssertEqual(Constants.OrderStatus.generating.rawValue, "GENERATING")
        XCTAssertEqual(Constants.OrderStatus.completed.rawValue, "COMPLETED")
        XCTAssertEqual(Constants.OrderStatus.failed.rawValue, "FAILED")
        XCTAssertEqual(Constants.OrderStatus.paid.rawValue, "PAID")
    }

    func testFaceQualityResult() {
        var result = FaceQualityResult()
        XCTAssertFalse(result.isAllPassed)
        result.isFrontal = true
        result.goodLighting = true
        result.noOcclusion = true
        result.sufficientResolution = true
        XCTAssertTrue(result.isAllPassed)
        XCTAssertTrue(result.failedReasons.isEmpty)
    }

    func testTemplateEquality() {
        let t1 = Template(id: "1", name: "A", category: "C", thumbnailURL: "", description: "", price: nil, isPremium: false)
        let t2 = Template(id: "1", name: "A", category: "C", thumbnailURL: "", description: "", price: nil, isPremium: false)
        XCTAssertEqual(t1, t2)
    }
}
