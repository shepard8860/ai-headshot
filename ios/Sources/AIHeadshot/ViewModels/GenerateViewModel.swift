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
            errorMessage = "\u521b\u5efa\u8ba2\u5355\u5931\u8d25: \(error.localizedDescription)"
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
                if event.progress >= 100.0 || event.status == Constants.OrderStatus.completed.rawValue || event.status == Constants.OrderStatus.paid.rawValue {
                    break
                }
                if event.status == Constants.OrderStatus.failed.rawValue {
                    errorMessage = event.errorMessage ?? "\u751f\u6210\u5931\u8d25"
                    break
                }
            }
        } catch {
            errorMessage = "\u8fdb\u5ea6\u8fde\u63a5\u4e2d\u65ad: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
