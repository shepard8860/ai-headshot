import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTemplate: Template?
    @State private var showCamera = false
    let userID: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.templates.isEmpty {
                    ProgressView("加载中...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.groupedTemplates.isEmpty {
                    emptyStateView
                } else {
                    templateList
                }
            }
            .navigationTitle("选择模板")
            .task {
                await viewModel.loadTemplates()
            }
            .sheet(isPresented: $showCamera) {
                if let template = selectedTemplate {
                    CameraView(template: template, userID: userID)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("暂无可用模板")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("请检查网络连接后重试")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("重试") {
                Task {
                    await viewModel.loadTemplates()
                }
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var templateList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(viewModel.groupedTemplates) { category in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(category.name)
                            .font(.title2.bold())
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 16) {
                                ForEach(category.templates) { template in
                                    TemplateCard(template: template) {
                                        selectedTemplate = template
                                        showCamera = true
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct TemplateCard: View {
    let template: Template
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: template.thumbnailURL)) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 160, height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 160, height: 200)
                            .overlay(Image(systemName: "photo"))
                    @unknown default:
                        EmptyView()
                    }
                }
                Text(template.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .foregroundColor(.primary)
                Text(template.description ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(width: 160)
        }
        .buttonStyle(.plain)
    }
}
