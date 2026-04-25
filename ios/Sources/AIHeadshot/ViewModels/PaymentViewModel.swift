import Foundation
import StoreKit

@MainActor
final class PaymentViewModel: ObservableObject {
    @Published var isPurchasing = false
    @Published var purchaseSuccess = false
    @Published var errorMessage: String?
    @Published var product: Product?

    func loadProduct() async {
        await IAPService.shared.loadProducts()
        product = IAPService.shared.products.first
    }

    func purchase(orderID: String) async {
        guard let product = product else {
            errorMessage = "商品未加载"
            return
        }
        isPurchasing = true
        errorMessage = nil
        do {
            _ = try await IAPService.shared.purchase(product)
            let receiptURL = Bundle.main.appStoreReceiptURL
            let receipt = receiptURL.flatMap { try? Data(contentsOf: $0).base64EncodedString() } ?? ""
            let result = try await APIService.shared.verifyPayment(orderID: orderID, receiptData: receipt)
            purchaseSuccess = result.success
        } catch let error as IAPService.IAPError where error == .userCancelled {
            // user cancelled, no error
        } catch {
            errorMessage = "支付失败: \(error.localizedDescription)"
        }
        isPurchasing = false
    }
}
