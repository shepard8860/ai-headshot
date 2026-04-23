import SwiftUI
import Foundation
import UIKit

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

extension URLRequest {
    mutating func setJSONContentType() {
        setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
}
