import Foundation

struct FaceQualityResult {
    var isFrontal: Bool = false
    var goodLighting: Bool = false
    var noOcclusion: Bool = false
    var sufficientResolution: Bool = false
    var confidence: Double = 0.0
    var message: String = ""

    var isAllPassed: Bool {
        isFrontal && goodLighting && noOcclusion && sufficientResolution
    }

    var failedReasons: [String] {
        var reasons: [String] = []
        if !isFrontal { reasons.append("请保持正面对准镜头") }
        if !goodLighting { reasons.append("光线不足，请到更亮的地方") }
        if !noOcclusion { reasons.append("检测到遮挡，请移除眼镜/口罩") }
        if !sufficientResolution { reasons.append("分辨率不足，请靠近一些") }
        return reasons
    }
}
