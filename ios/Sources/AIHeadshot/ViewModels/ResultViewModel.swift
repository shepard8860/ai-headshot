import Foundation

@MainActor
final class ResultViewModel: ObservableObject {
    @Published var thumbnails: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadResults(orderID: String) async {
        isLoading = true
        errorMessage = nil
        do {
            #if DEBUG
            try await Task.sleep(nanoseconds: 1_000_000_000)
            thumbnails = [
                "https://via.placeholder.com/300/blue",
                "https://via.placeholder.com/300/red",
                "https://via.placeholder.com/300/green",
                "https://via.placeholder.com/300/orange",
                "https://via.placeholder.com/300/purple",
                "https://via.placeholder.com/300/pink",
                "https://via.placeholder.com/300/cyan",
                "https://via.placeholder.com/300/yellow",
                "https://via.placeholder.com/300/gray"
            ]
            #else
            let result = try await APIService.shared.verifyPayment(orderID: orderID, receiptData: "")
            thumbnails = result.hdUrls ?? []
            #endif
        } catch {
            errorMessage = "加载结果失败: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
