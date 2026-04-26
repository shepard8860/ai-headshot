import SwiftUI

struct ResultView: View {
    let orderID: String
    @StateObject private var viewModel = ResultViewModel()
    @State private var selectedImageURL: String?
    @State private var showPayment = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("生成结果")
                    .font(.title.bold())
                    .padding(.top)

                if viewModel.isLoading {
                    ProgressView("加载结果中...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("重试") {
                            Task {
                                await viewModel.loadResults(orderID: orderID)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if viewModel.thumbnails.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("暂无生成结果")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        ForEach(viewModel.thumbnails, id: \.self) { url in
                            ThumbnailCell(url: url) {
                                selectedImageURL = url
                            }
                        }
                    }
                    .padding(.horizontal)

                    Button("解锁高清原图") {
                        showPayment = true
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
        }
        .sheet(isPresented: Binding<Bool>(
            get: { selectedImageURL != nil },
            set: { if !$0 { selectedImageURL = nil } }
        )) {
            if let url = selectedImageURL {
                ImagePreviewSheet(url: url)
            }
        }
        .sheet(isPresented: $showPayment) {
            PaymentView(orderID: orderID)
        }
        .task {
            await viewModel.loadResults(orderID: orderID)
        }
    }
}

struct ThumbnailCell: View {
    let url: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Color.red.opacity(0.1)
                    @unknown default:
                        EmptyView()
                    }
                }
                .aspectRatio(1, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("水印")
                    .font(.caption2)
                    .padding(4)
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .padding(4)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ImagePreviewSheet: View {
    let url: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    default:
                        ProgressView()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}


