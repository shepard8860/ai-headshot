import SwiftUI

struct ProfileView: View {
    #if DEBUG
    @State private var orders: [Order] = sampleOrders
    #else
    @State private var orders: [Order] = []
    #endif
    @State private var selectedOrder: Order?
    @State private var appearAnimation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                Group {
                    if orders.isEmpty {
                        emptyStateView
                    } else {
                        orderList
                    }
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedOrder) { order in
                OrderDetailView(order: order)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    appearAnimation = true
                }
            }
        }
    }

    private var orderList: some View {
        ScrollView {
            VStack(spacing: 20) {
                // User Header
                userHeader

                // Orders Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("历史订单")
                            .font(.title3.bold())
                        Spacer()
                        Text("\(orders.count) 个")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)

                    LazyVStack(spacing: 12) {
                        ForEach(Array(orders.enumerated()), id: \.element.id) { index, order in
                            OrderCard(order: order)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedOrder = order
                                }
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 16)
                                .animation(
                                    .easeOut(duration: 0.4).delay(Double(index) * 0.06),
                                    value: appearAnimation
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 12)
        }
    }

    private var userHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.35, green: 0.25, blue: 0.65),
                                Color(red: 0.5, green: 0.3, blue: 0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                Text("用")
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("欢迎使用 AI职业照")
                    .font(.headline)
                Text("选择模板，拍照生成专业形象照")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, 20)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 12)
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

// MARK: - Order Card

struct OrderCard: View {
    let order: Order
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))

                if let urlString = order.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Color.clear
                        }
                    }
                }

                if order.imageURL == nil {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("订单 #\(order.id.prefix(8).uppercased())")
                        .font(.subheadline.bold())
                    Spacer()
                    statusBadge
                }

                Text(order.templateID)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(order.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.12)) { isPressed = true }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.12)) { isPressed = false }
        }
    }

    private var statusBadge: some View {
        Text(order.status.rawValue)
            .font(.caption2.bold())
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.12))
            .clipShape(Capsule())
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

// MARK: - Order Detail

struct OrderDetailView: View {
    let order: Order
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Image
                    if let urlString = order.imageURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            default:
                                placeholderImage
                            }
                        }
                    } else {
                        placeholderImage
                    }

                    // Info Card
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(icon: "number", label: "订单号", value: order.id)
                        Divider()
                        DetailRow(icon: "square.grid.2x2", label: "模板", value: order.templateID)
                        Divider()
                        DetailRow(icon: "checkmark.shield", label: "状态", value: order.status.rawValue, valueColor: statusColor)
                        Divider()
                        DetailRow(icon: "creditcard", label: "支付", value: order.paid ? "已支付" : "未支付", valueColor: order.paid ? .green : .orange)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )

                    // Share Button
                    if order.paid, let urlString = order.imageURL, let url = URL(string: urlString) {
                        ShareLink(item: url) {
                            Label("分享 / 下载", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.35, green: 0.25, blue: 0.65))
                    }
                }
                .padding(20)
            }
            .navigationTitle("订单详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 280)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("暂无预览")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
    }

    private var statusColor: Color {
        switch order.status {
        case .completed, .paid: return .green
        case .failed: return .red
        case .generating: return .orange
        default: return .secondary
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Sample Data

private let sampleOrders: [Order] = [
    Order(
        id: "ord-001",
        templateID: "tpl-business",
        status: .paid,
        imageURL: nil,
        createdAt: Date().addingTimeInterval(-86400),
        updatedAt: Date(),
        paid: true
    ),
    Order(
        id: "ord-002",
        templateID: "tpl-creative",
        status: .completed,
        imageURL: nil,
        createdAt: Date().addingTimeInterval(-172800),
        updatedAt: Date(),
        paid: false
    )
]
