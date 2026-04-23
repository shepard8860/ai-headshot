import SwiftUI

struct ProfileView: View {
    @State private var orders: [Order] = sampleOrders
    @State private var selectedOrder: Order?

    var body: some View {
        NavigationStack {
            Group {
                if orders.isEmpty {
                    emptyStateView
                } else {
                    List {
                        Section(header: Text("历史订单")) {
                            ForEach(orders) { order in
                                OrderRow(order: order)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedOrder = order
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("我的")
            .sheet(item: $selectedOrder) { order in
                OrderDetailView(order: order)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.image")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("暂无订单")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("完成第一次拍照生成后，订单将显示在这里")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct OrderRow: View {
    let order: Order

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("订单 #\(order.id.prefix(8))")
                    .font(.subheadline.bold())
                Text(order.status.rawValue)
                    .font(.caption)
                    .foregroundColor(statusColor)
                Text(order.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if order.paid {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch order.status {
        case .completed, .paid:
            return .green
        case .failed:
            return .red
        case .generating:
            return .orange
        default:
            return .secondary
        }
    }
}

struct OrderDetailView: View {
    let order: Order
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let urlString = order.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit
                                .cornerRadius(12)
                        default:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 300)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(label: "订单号", value: order.id)
                    InfoRow(label: "模板", value: order.templateID)
                    InfoRow(label: "状态", value: order.status.rawValue)
                    InfoRow(label: "支付", value: order.paid ? "已支付" : "未支付")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                if order.paid, let urlString = order.imageURL, let url = URL(string: urlString) {
                    ShareLink(item: url) {
                        Label("分享/下载", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("订单详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

private let sampleOrders: [Order] = [
    Order(id: "ord-001", templateID: "tpl-business", status: .paid, imageURL: "https://via.placeholder.com/400", createdAt: Date().addingTimeInterval(-86400), updatedAt: Date(), paid: true),
    Order(id: "ord-002", templateID: "tpl-creative", status: .completed, imageURL: "https://via.placeholder.com/400", createdAt: Date().addingTimeInterval(-172800), updatedAt: Date(), paid: false)
]
