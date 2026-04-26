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
            guard let receiptURL = Bundle.main.appStoreReceiptURL else {
                throw NSError(domain: "Payment", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法获取购买收据"])
            }
            let data = try Data(contentsOf: receiptURL)
            let receipt = data.base64EncodedString()
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
