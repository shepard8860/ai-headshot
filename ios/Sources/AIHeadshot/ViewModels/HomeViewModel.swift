import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var templates: [Template] = []
    @Published var groupedTemplates: [TemplateCategory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let categoryDisplayNames: [String: String] = [
        "business": "商务",
        "creative": "创意",
        "id": "证件照",
        "social": "社交",
        "classic": "经典",
        "modern": "现代",
        "formal": "正式",
        "casual": "休闲",
        "artistic": "艺术",
        "vintage": "复古",
        "minimal": "简约"
    ]

    func loadTemplates() async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await APIService.shared.fetchTemplates()
            templates = data
            groupByCategory()
        } catch {
            errorMessage = "加载模板失败: \(error.localizedDescription)"
            AppLogger.network.error("\(error.localizedDescription)")
        }
        isLoading = false
    }

    private func groupByCategory() {
        let dict = Dictionary(grouping: templates, by: \.category)
        groupedTemplates = dict.map { key, value in
            let displayName = categoryDisplayNames[key.lowercased()] ?? key.capitalized
            return TemplateCategory(name: displayName, templates: value)
        }
        .sorted { $0.name < $1.name }
    }
}
