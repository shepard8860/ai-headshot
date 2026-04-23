import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var templates: [Template] = []
    @Published var groupedTemplates: [TemplateCategory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

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
        groupedTemplates = dict.map { TemplateCategory(name: $0.key, templates: $0.value) }
            .sorted { $0.name < $1.name }
    }
}
