import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTemplate: Template?
    @State private var showCamera = false
    @State private var appearAnimation = false
    let userID: String

    private let cardSpacing: CGFloat = 16
    private let horizontalPadding: CGFloat = 20
    private var cardWidth: CGFloat {
        let screenW = UIScreen.main.bounds.width
        // 大屏显示约1.8张，小屏显示约2张
        let cardsPerScreen = screenW > 400 ? 1.8 : 2.2
        return (screenW - horizontalPadding * 2 - cardSpacing) / cardsPerScreen
    }
    private var cardHeight: CGFloat { cardWidth * 0.85 }

    var body: some View {
        NavigationStack {
            content
                .background(Color(.systemGroupedBackground))
                .navigationTitle("选择模板")
                .navigationBarTitleDisplayMode(.large)
                .task {
                    await viewModel.loadTemplates()
                    withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                        appearAnimation = true
                    }
                }
                .sheet(isPresented: $showCamera) {
                    if let template = selectedTemplate {
                        CameraView(template: template, userID: userID)
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.templates.isEmpty {
            loadingView
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else if viewModel.groupedTemplates.isEmpty {
            emptyStateView
        } else {
            templateList
        }
    }

    private var loadingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                shimmerBanner
                ForEach(0..<3) { _ in
                    shimmerSection
                }
            }
            .padding(.vertical)
        }
    }

    private var shimmerBanner: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.gray.opacity(0.15))
            .frame(height: 140)
            .padding(.horizontal, horizontalPadding)
            .shimmer()
    }

    private var shimmerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 120, height: 28)
                .padding(.horizontal, horizontalPadding)
                .shimmer()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: cardSpacing) {
                    ForEach(0..<4) { _ in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: cardWidth, height: cardHeight)
                            .shimmer()
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
    }

    private var templateList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                heroBanner

                ForEach(Array(viewModel.groupedTemplates.enumerated()), id: \.element.id) { index, category in
                    categorySection(category: category, index: index)
                }
            }
            .padding(.vertical, 12)
        }
    }

    private var heroBanner: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.22, blue: 0.45),
                    Color(red: 0.35, green: 0.25, blue: 0.60)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    Text("专业AI职业照")
                        .font(.title2.bold())
                }
                Text("选择模板 → 拍照 → AI生成专业形象照")
                    .font(.subheadline)
                    .opacity(0.85)
            }
            .padding(20)
        }
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, horizontalPadding)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    private func categorySection(category: TemplateCategory, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category.name)
                    .font(.title3.bold())
                    .foregroundColor(.primary)

                Spacer()

                Text("\(category.templates.count) 个")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: cardSpacing) {
                    ForEach(category.templates) { template in
                        TemplateCard(
                            template: template,
                            width: cardWidth,
                            height: cardHeight
                        ) {
                            selectedTemplate = template
                            showCamera = true
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 24)
        .animation(
            .easeOut(duration: 0.5).delay(Double(index) * 0.08 + 0.15),
            value: appearAnimation
        )
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button(action: {
                Task { await viewModel.loadTemplates() }
            }) {
                Label("重试", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: Template
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                // Image Area
                ZStack {
                    // 渐变占位背景（不依赖网络）
                    gradientPlaceholder

                    AsyncImage(url: URL(string: template.thumbnailURL)) { phase in
                        switch phase {
                        case .empty:
                            Color.clear
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Color.clear
                        @unknown default:
                            Color.clear
                        }
                    }
                }
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )

                // Text Area
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        Text(template.description ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        if template.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            .frame(width: width)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.15)) { isPressed = true }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.15)) { isPressed = false }
        }
    }

    private var gradientPlaceholder: some View {
        let colors = gradientColors(for: template.id)
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: iconForCategory(template.category))
                .font(.system(size: width * 0.25))
                .foregroundColor(.white.opacity(0.3))
        )
    }

    private func gradientColors(for id: String) -> [Color] {
        let palettes: [[Color]] = [
            [Color(red: 0.4, green: 0.3, blue: 0.7), Color(red: 0.2, green: 0.15, blue: 0.45)],
            [Color(red: 0.2, green: 0.5, blue: 0.7), Color(red: 0.1, green: 0.25, blue: 0.5)],
            [Color(red: 0.6, green: 0.3, blue: 0.4), Color(red: 0.35, green: 0.15, blue: 0.25)],
            [Color(red: 0.3, green: 0.55, blue: 0.35), Color(red: 0.15, green: 0.3, blue: 0.2)],
            [Color(red: 0.5, green: 0.4, blue: 0.2), Color(red: 0.3, green: 0.2, blue: 0.1)],
            [Color(red: 0.5, green: 0.25, blue: 0.55), Color(red: 0.3, green: 0.15, blue: 0.35)]
        ]
        var hasher = Hasher()
        hasher.combine(id)
        let idx = abs(hasher.finalize()) % palettes.count
        return palettes[idx]
    }

    private func iconForCategory(_ category: String) -> String {
        let map: [String: String] = [
            "business": "briefcase.fill",
            "creative": "paintbrush.fill",
            "id": "idcard.fill",
            "social": "person.2.fill",
            "classic": "crown.fill",
            "modern": "star.fill",
            "formal": "tuxedo",
            "casual": "tshirt.fill",
            "artistic": "theatermasks.fill",
            "vintage": "clock.fill",
            "minimal": "minus.circle.fill"
        ]
        return map[category.lowercased()] ?? "photo.fill"
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.4),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + phase * geo.size.width * 2)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Press Events Helper

struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}
