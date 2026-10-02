import SwiftUI

/// `CustomSheetView` の見た目を決める設定。
struct CustomSheetConfig {
    var headerTint: Color = .yellow
    /// 一番小さく畳んだとき(コンパクト)のパネルの高さ。
    var smallestDetentHeight: CGFloat = 80
    /// ハーフ以上のときのヘッダー画像の高さ。
    var expandedImageHeight: CGFloat = 240
}

/// 地図の上に重ねて使う下部パネル。システムのシートではなく自前で描くので、
/// コンパクト時はバナーと円形の追加ボタンを完全に別のビューとして横並びにできる。
///
/// - コンパクト → ハーフ → 全開の3段階に、ヘッダーのドラッグで吸着する。
/// - ヘッダーはパネルの高さに連動して変形する。ハーフの高さで、すでにヘッダー画像が全開になる。
/// - 全開後のスクロールでは、ヘッダー画像が縮む。
/// - 追加ボタンはコンパクトのときだけバナーの右に出て、開くと消える。
struct CustomSheetView<Content: View>: View {
    @Binding var config: CustomSheetConfig
    var title: String
    var caption: String
    var headerImage: Image
    /// 指定すると、コンパクト時にバナーの右へ円形の追加ボタンを出す。
    var onAdd: (() -> Void)?
    @ViewBuilder var content: Content

    private enum Detent {
        case compact, half, full
    }

    @State private var detent: Detent = .compact
    @GestureState private var dragTranslation: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0

    private let compactImageSize: CGFloat = 48
    private let headerPadding: CGFloat = 16
    private let addButtonSize: CGFloat = 56
    private let addButtonGap: CGFloat = 10
    private let compactMargin: CGFloat = 16
    private let expandedMargin: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            let fullHeight = proxy.size.height - proxy.safeAreaInsets.top - 8
            let compactHeight = config.smallestDetentHeight
            let halfHeight = (fullHeight + compactHeight) / 2
            let baseHeight = height(for: detent, compact: compactHeight, half: halfHeight, full: fullHeight)
            let panelHeight = min(max(baseHeight - dragTranslation, compactHeight), fullHeight)
            // ハーフの高さで 1 になる。
            let progress = min(max((panelHeight - compactHeight) / (halfHeight - compactHeight), 0), 1)

            let margin = lerp(compactMargin, expandedMargin, progress)
            let bottomMargin = lerp(28, 8, progress)
            let reserve = onAdd == nil ? 0 : (addButtonSize + addButtonGap) * max(1 - progress * 3, 0)
            let panelWidth = proxy.size.width - margin * 2 - reserve
            let expandedImageWidth = proxy.size.width - expandedMargin * 2 - headerPadding * 2

            GlassEffectContainer(spacing: 4) {
                ZStack(alignment: .bottomLeading) {
                panel(
                    progress: progress,
                    height: panelHeight,
                    width: panelWidth,
                    expandedImageWidth: expandedImageWidth,
                    heights: (compactHeight, halfHeight, fullHeight)
                )
                .padding(.leading, margin)
                .padding(.bottom, bottomMargin)

                if let onAdd {
                    addButton(action: onAdd)
                        .opacity(max(1 - progress * 4, 0))
                        .allowsHitTesting(progress < 0.1)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, margin)
                        .padding(.bottom, bottomMargin + (compactHeight - addButtonSize) / 2)
                }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }

    // MARK: - Panel

    private func panel(
        progress: CGFloat,
        height: CGFloat,
        width: CGFloat,
        expandedImageWidth: CGFloat,
        heights: (compact: CGFloat, half: CGFloat, full: CGFloat)
    ) -> some View {
        let headerHeight = headerHeight(progress: progress, compact: heights.compact)

        return ZStack(alignment: .top) {
            ScrollView(.vertical) {
                content
                    .padding(.top, headerHeight)
            }
            .scrollDisabled(detent != .full)
            .background(Color(.systemBackground).opacity(min(progress * 4, 1)))
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                max(geometry.contentOffset.y + geometry.contentInsets.top, 0)
            } action: { _, newValue in
                scrollOffset = newValue
            }

            header(progress: progress, height: headerHeight, expandedImageWidth: expandedImageWidth)
                .gesture(dragGesture(heights: heights))
        }
        .frame(width: width, height: height, alignment: .top)
        .clipShape(panelShape(progress: progress))
        // Liquid Glass。ヘッダーの色を tint として乗せる。
        .glassEffect(.regular.tint(config.headerTint.opacity(0.3)), in: panelShape(progress: progress))
    }

    private func panelShape(progress: CGFloat) -> UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: lerp(40, 36, progress),
            bottomLeadingRadius: 40,
            bottomTrailingRadius: 40,
            topTrailingRadius: lerp(40, 36, progress)
        )
    }

    // MARK: - Header

    private func header(progress: CGFloat, height: CGFloat, expandedImageWidth: CGFloat) -> some View {
        // 全開後のスクロール量で、画像を最大で半分まで縮める。
        let collapse = min(scrollOffset / 120, 1) * progress
        let imageHeight = lerp(compactImageSize, config.expandedImageHeight * (1 - 0.5 * collapse), progress)
        let imageWidth = lerp(compactImageSize, expandedImageWidth, progress)
        let radius = lerp(10, 20, progress)
        // 畳み側と展開側のタイトルを重ならないようにクロスフェードする。
        let compactOpacity = max(1 - progress * 4, 0)
        let expandedOpacity = max(progress * 2 - 1, 0)

        return ZStack(alignment: .topLeading) {
            headerImage
                .resizable()
                .scaledToFill()
                .frame(width: imageWidth, height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: radius))

            titleBlock(fontSize: 16)
                .frame(height: compactImageSize, alignment: .center)
                .padding(.leading, compactImageSize + 12)
                .opacity(compactOpacity)

            titleBlock(fontSize: 24)
                .padding(.top, imageHeight + 12)
                .opacity(expandedOpacity)
        }
        .padding(.horizontal, headerPadding)
        .padding(.top, lerp(16, 24, progress))
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .topLeading)
        .overlay(alignment: .top) {
            Capsule()
                .fill(.secondary.opacity(0.6))
                .frame(width: 36, height: 5)
                .padding(.top, 6)
        }
        .contentShape(Rectangle())
    }

    private func titleBlock(fontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: fontSize, weight: .bold))
                .lineLimit(1)
            if !caption.isEmpty {
                Text(caption)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private func addButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: addButtonSize, height: addButtonSize)
                .glassEffect(.regular.tint(config.headerTint.opacity(0.3)).interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("写真を追加")
    }

    // MARK: - Dragging

    private func dragGesture(heights: (compact: CGFloat, half: CGFloat, full: CGFloat)) -> some Gesture {
        DragGesture()
            .updating($dragTranslation) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                // 指を離した後の慣性を含めた到達点に、一番近い高さへ吸着する。
                let current = height(for: detent, compact: heights.compact, half: heights.half, full: heights.full)
                let projected = current - value.predictedEndTranslation.height
                let candidates: [(Detent, CGFloat)] = [
                    (.compact, heights.compact),
                    (.half, heights.half),
                    (.full, heights.full),
                ]
                let nearest = candidates.min { abs($0.1 - projected) < abs($1.1 - projected) }?.0 ?? detent
                withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                    detent = nearest
                }
            }
    }

    // MARK: - Geometry

    private func height(for detent: Detent, compact: CGFloat, half: CGFloat, full: CGFloat) -> CGFloat {
        switch detent {
        case .compact: compact
        case .half: half
        case .full: full
        }
    }

    private func headerHeight(progress: CGFloat, compact: CGFloat) -> CGFloat {
        let collapse = min(scrollOffset / 120, 1) * progress
        let expanded = config.expandedImageHeight * (1 - 0.5 * collapse) + 24 + 12 + 12 + 40
        return lerp(compact, expanded, progress)
    }

    private func lerp(_ from: CGFloat, _ to: CGFloat, _ t: CGFloat) -> CGFloat {
        from + (to - from) * t
    }
}

#Preview {
    @Previewable @State var config = CustomSheetConfig()
    Color.gray.opacity(0.2)
        .ignoresSafeArea()
        .overlay {
            CustomSheetView(
                config: $config,
                title: "代々木公園入口",
                caption: "2026年10月2日 18:11",
                headerImage: Image(systemName: "photo"),
                onAdd: {}
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(0..<20) { index in
                        Text("行 \(index)")
                    }
                }
                .padding()
            }
        }
}
