import Foundation

@MainActor
final class GenerateViewModel: ObservableObject {
    @Published var orderID: String = ""
    @Published var progress: Double = 0.0
    @Published var statusMessage: String = "准备中..."
    @Published var orderStatus: Constants.OrderStatus = .pending
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var resultImageURLs: [String] = []

    func startGeneration(userID: String, templateID: String, imageURL: String) async {
        isLoading = true
        errorMessage = nil
        resultImageURLs = []
        do {
            let id = try await APIService.shared.createOrder(userID: userID, templateID: templateID, imageURL: imageURL)
            orderID = id
            await listenToProgress(orderID: id)
        } catch {
            errorMessage = "创建订单失败: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func listenToProgress(orderID: String) async {
        let stream = APIService.shared.streamOrderStatus(orderID: orderID)
        do {
            for try await event in stream {
                progress = event.progress
                statusMessage = event.message ?? event.status
                if let status = Constants.OrderStatus(rawValue: event.status) {
                    orderStatus = status
                }
                if let urls = event.previewUrls {
                    resultImageURLs = urls
                }
                if event.progress >= 100.0 ||
                    event.status == Constants.OrderStatus.completed.rawValue ||
                    event.status == Constants.OrderStatus.paid.rawValue {
                    break
                }
                if event.status == Constants.OrderStatus.failed.rawValue {
                    errorMessage = event.errorMessage ?? "生成失败"
                    break
                }
            }
        } catch {
            errorMessage = "进度连接中断: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
