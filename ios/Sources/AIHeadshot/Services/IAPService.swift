import Foundation
import StoreKit

@MainActor
final class IAPService: ObservableObject {
    static let shared = IAPService()
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []

    private init() {}

    func loadProducts() async {
        do {
            let ids = [Constants.productID]
            products = try await Product.products(for: ids)
            AppLogger.iap.info("Loaded \(products.count) products")
        } catch {
            AppLogger.iap.error("Failed to load products: \(error.localizedDescription)")
        }
    }

    func purchase(_ product: Product) async throws -> Transaction {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            purchasedProductIDs.insert(product.id)
            AppLogger.iap.info("Purchase success: \(product.id)")
            return transaction
        case .userCancelled:
            throw IAPError.userCancelled
        case .pending:
            throw IAPError.pending
        @unknown default:
            throw IAPError.unknown
        }
    }

    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw IAPError.unverified
        case .verified(let safe):
            return safe
        }
    }

    enum IAPError: Error {
        case userCancelled
        case pending
        case unverified
        case unknown
    }
}
