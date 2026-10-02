import SwiftUI

/// `CustomSheetView` の見た目を決める設定。
struct CustomSheetConfig {
    var headerTint: Color = .yellow
    /// 一番小さく畳んだとき(コンパクト)のパネルの高さ。
    var smallestDetentHeight: CGFloat = 64
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

    private let compactImageSize: CGFloat = 40
    private let headerPadding: CGFloat = 16
    /// 追加ボタンはコンパクトのバナーと同じ高さの円にする。
    private var addButtonSize: CGFloat { config.smallestDetentHeight }
    private let addButtonGap: CGFloat = 10
    /// 広がったときに写真の上へ確保する、×ボタンの行の高さ。
    private let closeBarHeight: CGFloat = 44
    private let compactMargin: CGFloat = 16
    private let expandedMargin: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            // 全開は上のセーフエリアの下まで。ステータスバー側にはみ出さない。
            let fullHeight = proxy.size.height - Self.windowSafeAreaTop
            let compactHeight = config.smallestDetentHeight
            let halfHeight = (fullHeight + compactHeight) / 2
            let baseHeight = height(for: detent, compact: compactHeight, half: halfHeight, full: fullHeight)
            let panelHeight = min(max(baseHeight - dragTranslation, compactHeight), fullHeight)
            // ハーフの高さで 1 になる。
            let progress = min(max((panelHeight - compactHeight) / (halfHeight - compactHeight), 0), 1)
            // ハーフ→全開で 0 → 1。全開に近づくほど中身の背景を白くする。
            let fullProgress = min(max((panelHeight - halfHeight) / (fullHeight - halfHeight), 0), 1)

            // 全開に近づくほど余白と角丸をなくして、画面いっぱいにする。
            let edge = 1 - fullProgress
            let topExtra: CGFloat = 0
            let margin = lerp(compactMargin, expandedMargin, progress) * edge
            let bottomMargin = lerp(28, 8, progress) * edge
            let reserve = onAdd == nil ? 0 : (addButtonSize + addButtonGap) * max(1 - progress * 3, 0)
            let panelWidth = proxy.size.width - margin * 2 - reserve
            let expandedImageWidth = proxy.size.width - margin * 2 - headerPadding * 2

            ZStack(alignment: .bottomLeading) {
                panel(
                    progress: progress,
                    fullProgress: fullProgress,
                    topExtra: topExtra,
                    height: panelHeight,
                    width: panelWidth,
                    expandedImageWidth: expandedImageWidth,
                    heights: (compactHeight, halfHeight, fullHeight)
                )
                .padding(.leading, margin)
                .padding(.bottom, bottomMargin)

                // 広がるにつれて薄く小さくして消す。ガラスの opacity が効くよう、パネルとは別のビューにしてある。
                if let onAdd, progress < 1 {
                    let fade = 1 - progress
                    addButton(action: onAdd)
                        .opacity(fade)
                        .scaleEffect(0.6 + 0.4 * fade)
                        .allowsHitTesting(progress < 0.3)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, margin)
                        .padding(.bottom, bottomMargin)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            // 全開のときは、上のセーフエリア(ステータスバー側)も白にする。
            .overlay(alignment: .top) {
                Color(.systemBackground)
                    .frame(height: Self.windowSafeAreaTop)
                    .opacity(fullProgress)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Panel

    private func panel(
        progress: CGFloat,
        fullProgress: CGFloat,
        topExtra: CGFloat,
        height: CGFloat,
        width: CGFloat,
        expandedImageWidth: CGFloat,
        heights: (compact: CGFloat, half: CGFloat, full: CGFloat)
    ) -> some View {
        let headerHeight = headerHeight(progress: progress, fullProgress: fullProgress, compact: heights.compact) + topExtra

        return ZStack(alignment: .top) {
            ScrollView(.vertical) {
                content
                    .padding(.top, headerHeight)
            }
            .scrollDisabled(detent != .full)
            // ハーフまでは透明(ガラス越し)、全開で白。
            .background(Color(.systemBackground).opacity(fullProgress))
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                max(geometry.contentOffset.y + geometry.contentInsets.top, 0)
            } action: { _, newValue in
                scrollOffset = newValue
            }

            header(progress: progress, fullProgress: fullProgress, height: headerHeight, topExtra: topExtra, expandedImageWidth: expandedImageWidth)
                .gesture(dragGesture(heights: heights))
        }
        .frame(width: width, height: height, alignment: .top)
        .clipShape(panelShape(progress: progress, edge: 1 - fullProgress))
        // Liquid Glass。ヘッダーの色を tint として乗せる。
        .glassEffect(.regular.tint(config.headerTint.opacity(0.3)), in: panelShape(progress: progress, edge: 1 - fullProgress))
    }

    /// コンパクトはカプセル、広がるにつれて端末の画面角に同心の丸みへ移る。全開では角丸なし。
    /// パネルの角の半径(全開で 0 にする前の値)。
    private func panelRadius(progress: CGFloat) -> CGFloat {
        let capsule = config.smallestDetentHeight / 2
        let concentric = max(Self.deviceCornerRadius - expandedMargin, 0)
        return lerp(capsule, concentric, progress)
    }

    private func panelShape(progress: CGFloat, edge: CGFloat) -> UnevenRoundedRectangle {
        let radius = panelRadius(progress: progress) * edge
        return UnevenRoundedRectangle(
            topLeadingRadius: radius,
            bottomLeadingRadius: radius,
            bottomTrailingRadius: radius,
            topTrailingRadius: radius
        )
    }

    // MARK: - Header

    private func header(progress: CGFloat, fullProgress: CGFloat, height: CGFloat, topExtra: CGFloat, expandedImageWidth: CGFloat) -> some View {
        // 全開後のスクロール量で、画像を最大で半分まで縮める。
        let collapse = min(scrollOffset / 120, 1) * progress
        let imageHeight = lerp(compactImageSize, config.expandedImageHeight * (1 - 0.5 * collapse), progress)
        let imageWidth = lerp(compactImageSize, expandedImageWidth, progress)
        // 写真の角は、パネルの角に同心(パネルの半径 - 写真までの余白)。全開ではパネルの角が消えるので 20 に寄せる。
        let inset = lerp((config.smallestDetentHeight - compactImageSize) / 2, headerPadding, progress)
        let concentricRadius = max(panelRadius(progress: progress) - inset, 0)
        let radius = lerp(concentricRadius, 20, fullProgress)
        // 畳み側と展開側のタイトルを重ならないようにクロスフェードする。
        let compactOpacity = max(1 - progress * 4, 0)
        let expandedOpacity = max(progress * 2 - 1, 0)
        // 写真は×ボタンの行の下に置く(×は全開のときだけなので、行も全開に向けて確保する)。
        let barHeight = closeBarHeight * fullProgress

        return ZStack(alignment: .topLeading) {
            headerImage
                .resizable()
                .scaledToFill()
                .frame(width: imageWidth, height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: radius))
                .padding(.top, barHeight)

            titleBlock(fontSize: 16)
                .frame(height: compactImageSize, alignment: .center)
                .padding(.leading, compactImageSize + 12)
                .opacity(compactOpacity)

            titleBlock(fontSize: 24)
                .padding(.top, barHeight + imageHeight + 12)
                .opacity(expandedOpacity)

            closeButton
                .frame(maxWidth: .infinity, alignment: .trailing)
                // 全開のときだけ表示する(ハーフでは出さない)。
                .opacity(fullProgress)
                .allowsHitTesting(fullProgress > 0.9)
        }
        .padding(.horizontal, headerPadding)
        .padding(.top, lerp((config.smallestDetentHeight - compactImageSize) / 2, 24, progress) + topExtra)
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .topLeading)
        .overlay(alignment: .top) {
            Capsule()
                .fill(.secondary.opacity(0.6))
                .frame(width: 36, height: 5)
                .padding(.top, 6 + topExtra)
        }
        .contentShape(Rectangle())
    }

    private var closeButton: some View {
        Button {
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                detent = .compact
            }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 32, height: 32)
                .background(.thinMaterial, in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("閉じる")
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
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("写真を追加")
    }

    // MARK: - Dragging

    private func dragGesture(heights: (compact: CGFloat, half: CGFloat, full: CGFloat)) -> some Gesture {
        DragGesture(coordinateSpace: .global)
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

    private func headerHeight(progress: CGFloat, fullProgress: CGFloat, compact: CGFloat) -> CGFloat {
        let collapse = min(scrollOffset / 120, 1) * progress
        let expanded = closeBarHeight * fullProgress + config.expandedImageHeight * (1 - 0.5 * collapse) + 24 + 12 + 12 + 40
        return lerp(compact, expanded, progress)
    }

    /// 親が ignoresSafeArea() のため proxy からは取れないので、ウィンドウから読む。
    private static var windowSafeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets.top ?? 0
    }

    /// 端末の画面角の半径。公開 API が無いため、取れなければ近い値を使う。
    private static var deviceCornerRadius: CGFloat {
        let screen = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen
        let value = (screen?.value(forKey: "_displayCornerRadius") as? CGFloat) ?? 0
        return value > 0 ? value : 55
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
