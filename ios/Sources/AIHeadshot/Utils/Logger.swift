import Foundation
import OSLog

enum AppLogger {
    static let network = Logger(subsystem: "com.ai-headshot", category: "Network")
    static let vision = Logger(subsystem: "com.ai-headshot", category: "Vision")
    static let iap = Logger(subsystem: "com.ai-headshot", category: "IAP")
    static let general = Logger(subsystem: "com.ai-headshot", category: "General")
}
