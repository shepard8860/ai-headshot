import SwiftUI
import StoreKit

struct PaymentView: View {
    let orderID: String
    @StateObject private var viewModel = PaymentViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "lock.open.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("解锁高清原图")
                    .font(.title2.bold())

                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "checkmark.circle.fill", text: "9张高清证件照")
                    FeatureRow(icon: "checkmark.circle.fill", text: "无水印下载")
                    FeatureRow(icon: "checkmark.circle.fill", text: "永久保存")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                if let product = viewModel.product {
                    VStack(spacing: 8) {
                        Text(product.displayPrice)
                            .font(.system(size: 36, weight: .bold))
                        Button(viewModel.isPurchasing ? "处理中..." : "立即支付") {
                            Task {
                                await viewModel.purchase(orderID: orderID)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isPurchasing)
                    }
                } else {
                    ProgressView("加载商品中...")
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if viewModel.purchaseSuccess {
                    Text("支付成功！已解锁高清图")
                        .foregroundColor(.green)
                        .font(.headline)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("支付")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .task {
                await viewModel.loadProduct()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}
