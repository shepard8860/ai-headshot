import XCTest
@testable import AIHeadshot

final class FaceDetectionServiceTests: XCTestCase {
    func testFaceQualityResultDefaults() {
        let result = FaceQualityResult()
        XCTAssertFalse(result.isAllPassed)
        XCTAssertEqual(result.confidence, 0.0)
        XCTAssertEqual(result.failedReasons.count, 4)
        XCTAssertTrue(result.failedReasons.contains("请保持正面对准镜头"))
    }

    func testFaceQualityResultAllPassed() {
        var result = FaceQualityResult()
        result.isFrontal = true
        result.goodLighting = true
        result.noOcclusion = true
        result.sufficientResolution = true
        result.confidence = 0.95
        XCTAssertTrue(result.isAllPassed)
        XCTAssertTrue(result.failedReasons.isEmpty)
        XCTAssertEqual(result.message, "人脸质量检测通过")
    }

    func testFaceQualityResultPartialFail() {
        var result = FaceQualityResult()
        result.isFrontal = true
        result.goodLighting = false
        result.noOcclusion = true
        result.sufficientResolution = true
        XCTAssertFalse(result.isAllPassed)
        XCTAssertEqual(result.failedReasons.count, 1)
        XCTAssertTrue(result.failedReasons.contains("光线不足，请到更亮的地方"))
    }

    func testFaceQualityResultMessageWhenFailed() {
        var result = FaceQualityResult()
        result.isFrontal = false
        result.goodLighting = false
        result.message = result.failedReasons.joined(separator: "\n")
        XCTAssertTrue(result.message.contains("请保持正面对准镜头"))
        XCTAssertTrue(result.message.contains("光线不足，请到更亮的地方"))
    }
}
