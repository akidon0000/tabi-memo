import SwiftUI

/// `CustomSheetView` の見た目を決める設定。
struct CustomSheetConfig {
    var headerTint: Color = .yellow
    /// 一番小さく畳んだとき(コンパクト)のパネルの高さ。
    var smallestDetentHeight: CGFloat = 64
    /// ハーフ以上のときのヘッダー画像の高さ。
    var expandedImageHeight: CGFloat = 240
}

/// 前後の写真の見た目。スワイプ中に後ろへ先読みして描く。
struct PageSnapshot {
    var title: String
    var image: Image
    var aspectRatio: CGFloat
    var content: AnyView
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
    /// ヘッダー画像の幅 / 高さ。縦長の写真は 1 より小さい値で、広がったときに高さを確保する。
    var headerAspectRatio: CGFloat = 1.5
    /// 指定すると、コンパクト時にバナーの右へ円形の追加ボタンを出す。
    var onAdd: (() -> Void)?
    /// 写真をタップしたとき(ハーフ・全開)。拡大表示を出すのに使う。
    var onImageTap: (() -> Void)?
    /// 左右スワイプで前後へ移れるか(step: 前 -1 / 次 +1)。nil ならスワイプで移らない。
    var canPage: ((Int) -> Bool)?
    /// 前後へ移る。呼び出し側が表示内容(title / headerImage / content)を差し替える。
    var onPage: ((Int) -> Void)?
    /// 前後の写真の内容(step: 前 -1 / 次 +1)。スワイプ中に後ろへ見せる。
    var neighbor: ((Int) -> PageSnapshot?)?
    @ViewBuilder var content: Content

    private enum Detent {
        case compact, half, full
    }

    @State private var detent: Detent = .compact
    @GestureState private var dragTranslation: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var barNudge: CGFloat = 0
    @State private var pageOffset: CGFloat = 0
    @State private var pageOpacity: CGFloat = 1
    @State private var pageScale: CGFloat = 1
    /// 入れ替わった直後の文字の濃さ(0→1)。
    @State private var textReveal: CGFloat = 1
    @State private var isSwiping = false
    @State private var peekStep = 1
    @State private var scrollPosition = ScrollPosition(edge: .top)
    /// 指がヘッダーに触れている間 true。揺らしの判定に使う(task から読めるよう @State に写す)。
    @GestureState private var isPressing = false
    @State private var isTouching = false

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
            // ハーフは「写真と日付だけ」の高さにする(メモなどの中身は全開で出す)。
            let halfImageWidth = proxy.size.width - expandedMargin * 2 - headerPadding * 2
            let halfCap = max(config.expandedImageHeight, fullHeight * 0.42)
            let halfOwnImage = min(max(halfImageWidth / max(headerAspectRatio, 0.2), config.expandedImageHeight), halfCap)
            let halfNextImage: CGFloat = {
                guard pageOffset != 0, let snap = neighbor?(peekStep) else { return halfOwnImage }
                return min(max(halfImageWidth / max(snap.aspectRatio, 0.2), config.expandedImageHeight), halfCap)
            }()
            let halfImage = lerp(halfOwnImage, halfNextImage, min(abs(pageOffset) / 160, 1))
            let halfHeight = min(halfImage + 24 + 12 + 12 + 40, fullHeight - 120)
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
            // 写真の縦横比どおりの高さにする。ハーフでは見切れない範囲、全開では画面の約6割までに収める。
            let fitHeight = expandedImageWidth / max(headerAspectRatio, 0.2)
            let fullCap = max(fullHeight * 0.6, halfCap)
            let imageCap = lerp(halfCap, fullCap, fullProgress)
            let ownImageHeight = min(max(fitHeight, config.expandedImageHeight), imageCap)
            // スワイプ先の写真の高さ。スワイプ量に応じて、レイアウト(文字の位置・パネル内の高さ)を先に移す。
            let nextImageHeight: CGFloat = {
                guard pageOffset != 0, let snap = neighbor?(peekStep) else { return ownImageHeight }
                return min(max(expandedImageWidth / max(snap.aspectRatio, 0.2), config.expandedImageHeight), imageCap)
            }()
            let swipeReveal = min(abs(pageOffset) / 160, 1)
            let expandedImageHeight = lerp(ownImageHeight, nextImageHeight, swipeReveal)

            ZStack(alignment: .bottomLeading) {
                panel(
                    progress: progress,
                    fullProgress: fullProgress,
                    topExtra: topExtra,
                    height: panelHeight,
                    width: panelWidth,
                    expandedImageWidth: expandedImageWidth,
                    expandedImageHeight: expandedImageHeight,
                    ownImageHeight: ownImageHeight,
                    nextImageHeight: nextImageHeight,
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
            .task(id: detent) { await runNudgeLoop() }
            .onChange(of: isPressing) { _, pressing in
                isTouching = pressing
                if pressing { withAnimation(.easeOut(duration: 0.1)) { barNudge = 0 } }
            }
            // 全開のときは、上のセーフエリア(ステータスバー側)も白にする。
            .overlay(alignment: .top) {
                Color(.systemBackground)
                    .frame(height: Self.windowSafeAreaTop)
                    .opacity(fullProgress)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Detent

    /// バーのタップ: コンパクト → ハーフ → 全開。全開では何もしない(畳むのは×やドラッグ)。
    private func advanceDetent() {
        let next: Detent? = switch detent {
        case .compact: .half
        case .half: .full
        case .full: nil
        }
        guard let next else { return }
        withAnimation(.spring(duration: 0.4, bounce: 0.15)) { detent = next }
    }

    // MARK: - Nudge

    /// 全開の間、一定間隔でバーを下へ揺らして、下にスワイプで畳めることを伝える。
    private func runNudgeLoop() async {
        barNudge = 0
        guard detent == .full else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(4))
            if Task.isCancelled { return }
            // 指で触れている間は揺らさない。
            if isTouching { continue }
            for offset: CGFloat in [10, 2, 8, 0] {
                if isTouching { break }
                withAnimation(.easeOut(duration: 0.12)) { barNudge = offset }
                try? await Task.sleep(for: .milliseconds(120))
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
        expandedImageHeight: CGFloat,
        ownImageHeight: CGFloat,
        nextImageHeight: CGFloat,
        heights: (compact: CGFloat, half: CGFloat, full: CGFloat)
    ) -> some View {
        let headerHeight = headerHeight(progress: progress, fullProgress: fullProgress, compact: heights.compact, imageHeight: expandedImageHeight) + topExtra

        return ZStack(alignment: .top) {
            // ハーフまでは透明(ガラス越し)、全開で白。スクロール側ではなくここに敷いて、後ろの先読みカードの下にも白が来るようにする。
            Color(.systemBackground).opacity(fullProgress)

            // 前後の写真を後ろに先読みして出す。スワイプ量に応じて手前へ寄ってくる。
            if pageOffset != 0, let snap = neighbor?(peekStep) {
                peekCard(snap, progress: progress, fullProgress: fullProgress, width: expandedImageWidth, expandedHeight: nextImageHeight, topPad: lerp((config.smallestDetentHeight - compactImageSize) / 2, 24 + closeBarHeight * fullProgress, progress) + topExtra)
            }

            ScrollView(.vertical) {
                content
                    .opacity((1 - min(abs(pageOffset) / 160, 1)) * textReveal * fullProgress)
                    // スワイプ先のメモも、スワイプ中から同じ位置に重ねて、動いた量に応じて濃くする。
                    .overlay(alignment: .top) {
                        if pageOffset != 0, let snap = neighbor?(peekStep) {
                            snap.content
                                .opacity(min(abs(pageOffset) / 160, 1) * fullProgress)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.top, headerHeight)
                    .overlay(alignment: .top) {
                        // 全開ではヘッダー層がタッチを通すので、写真の位置に透明なタップ領域を置く。
                        Color.clear
                            .frame(height: expandedImageHeight)
                            .contentShape(Rectangle())
                            .onTapGesture { onImageTap?() }
                            .padding(.top, 24 + closeBarHeight + topExtra)
                            .allowsHitTesting(detent == .full)
                    }
            }
            .scrollPosition($scrollPosition)
            .scrollDisabled(detent != .full)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                max(geometry.contentOffset.y + geometry.contentInsets.top, 0)
            } action: { _, newValue in
                scrollOffset = newValue
            }

            header(progress: progress, fullProgress: fullProgress, height: headerHeight, topExtra: topExtra, expandedImageWidth: expandedImageWidth, expandedImageHeight: expandedImageHeight, ownImageHeight: ownImageHeight, heights: heights)
        }
        // 左右スワイプで前後の写真へ(全開のみ)。指に追従して傾き、一定以上動かすと飛んでいって次の写真が入る(Tinder 風)。
        .simultaneousGesture(
            DragGesture(minimumDistance: 24, coordinateSpace: .global)
                .onChanged { value in
                    // 左右スワイプで写真を移るのは全開のときだけ。
                    guard detent == .full else { return }
                    let w = value.translation.width, h = value.translation.height
                    if !isSwiping {
                        guard abs(w) > 12, abs(w) > abs(h) * 1.5 else { return }
                        isSwiping = true
                    }
                    peekStep = w < 0 ? 1 : -1
                    // 移れない向き(端)では、抵抗をつけて少ししか動かさない。
                    let hasNeighbor = canPage?(w < 0 ? 1 : -1) == true
                    pageOffset = hasNeighbor ? w : w * 0.3
                    pageOpacity = 1 - min(abs(pageOffset) / 500, 0.5)
                }
                .onEnded { value in
                    guard isSwiping else { return }
                    isSwiping = false
                    let w = value.translation.width
                    let step = w < 0 ? 1 : -1
                    let flings = abs(w) > 110 || abs(value.predictedEndTranslation.width) > 260
                    if flings, canPage?(step) == true {
                        flingAway(step)
                    } else {
                        withAnimation(.spring(duration: 0.35, bounce: 0.25)) {
                            pageOffset = 0
                            pageOpacity = 1
                        }
                    }
                }
        )
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

    private func header(
        progress: CGFloat,
        fullProgress: CGFloat,
        height: CGFloat,
        topExtra: CGFloat,
        expandedImageWidth: CGFloat,
        expandedImageHeight: CGFloat,
        ownImageHeight: CGFloat,
        heights: (compact: CGFloat, half: CGFloat, full: CGFloat)
    ) -> some View {
        // 写真そのものは自分の高さのまま。文字はスワイプ先の高さに合わせた位置へ先に寄る。
        let imageHeight = lerp(compactImageSize, ownImageHeight, progress)
        let textImageHeight = lerp(compactImageSize, expandedImageHeight, progress)
        let imageWidth = lerp(compactImageSize, expandedImageWidth, progress)
        // 写真の角は、パネルの角に同心(パネルの半径 - 写真までの余白)。全開ではパネルの角が消えるので 20 に寄せる。
        let inset = lerp((config.smallestDetentHeight - compactImageSize) / 2, headerPadding, progress)
        let concentricRadius = max(panelRadius(progress: progress) - inset, 0)
        let radius = lerp(concentricRadius, 20, fullProgress)
        // 畳み側と展開側のタイトルを重ならないようにクロスフェードする。
        let compactOpacity = max(1 - progress * 4, 0)
        // 左右スワイプ中は、動いた量に応じて文字を薄くする。入れ替わったあと、次の文字が濃くなって出る。
        let textFade = (1 - min(abs(pageOffset) / 160, 1)) * textReveal
        let expandedOpacity = max(progress * 2 - 1, 0) * textFade
        // 写真は×ボタンの行の下に置く(×は全開のときだけなので、行も全開に向けて確保する)。
        let barHeight = closeBarHeight * fullProgress
        let topPad = lerp((config.smallestDetentHeight - compactImageSize) / 2, 24, progress) + topExtra

        // 写真とタイトル。全開ではスクロール量だけ上へ流す(中身と一緒に動く)。
        let scrolling = ZStack(alignment: .topLeading) {
            headerImage
                .resizable()
                .scaledToFill()
                .frame(width: imageWidth, height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: radius))
                // 左右スワイプで動くのは写真だけ。文字は動かさず、移動が終わってから切り替わる。
                .modifier(PageCard(offset: pageOffset, opacity: pageOpacity, scale: pageScale))
                .onTapGesture { if progress > 0.5 { onImageTap?() } }
                .padding(.top, barHeight)

            titleBlock(fontSize: 16)
                .frame(height: compactImageSize, alignment: .center)
                .padding(.leading, compactImageSize + 12)
                .opacity(compactOpacity * textFade)

            titleBlock(fontSize: 24)
                .padding(.top, barHeight + textImageHeight + 12)
                .opacity(expandedOpacity)

            // スワイプ先の日時。スワイプ中から現れ、手前の日時と入れ替わる。
            if pageOffset != 0, let snap = neighbor?(peekStep) {
                let reveal = min(abs(pageOffset) / 160, 1)
                Text(snap.title)
                    .font(.system(size: 24, weight: .bold))
                    .lineLimit(1)
                    .padding(.top, barHeight + textImageHeight + 12)
                    .opacity(max(progress * 2 - 1, 0) * reveal)
                Text(snap.title)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
                    .frame(height: compactImageSize, alignment: .center)
                    .padding(.leading, compactImageSize + 12)
                    .opacity(compactOpacity * reveal)
            }
        }
        .padding(.horizontal, headerPadding)
        .padding(.top, topPad)
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .topLeading)
        .offset(y: -scrollOffset * fullProgress)

        return ZStack(alignment: .top) {
            scrolling
                .contentShape(Rectangle())
                // 全開では下の ScrollView にタッチを通す(スクロール・縦ドラッグの競合を避ける)。
                .allowsHitTesting(detent != .full)
                .gesture(dragGesture(heights: heights))
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .updating($isPressing) { _, state, _ in state = true }
                )

            // 上に固定する行: ドラッグバー、×ボタン。専用の背景は敷かず、パネル全体の背景(全開で白)と同じ色にする。写真はこの下を、切り取られずに流れる。
            ZStack(alignment: .top) {
                Color.clear
                    .frame(height: 40 + topExtra)
                    .contentShape(Rectangle())
                    .onTapGesture { advanceDetent() }
                    .gesture(dragGesture(heights: heights))
                    .frame(maxHeight: .infinity, alignment: .top)

                Capsule()
                    .fill(.secondary.opacity(0.6))
                    .frame(width: 36, height: 5)
                    .padding(.top, 6 + topExtra)
                    // 全開で「下にスワイプできる」ことを知らせるときに、下へ揺らす。
                    .offset(y: barNudge)
                    .allowsHitTesting(false)
                    .frame(maxHeight: .infinity, alignment: .top)

                closeButton
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, headerPadding)
                    .padding(.top, 8 + topExtra)
                    // 全開のときだけ表示する(ハーフでは出さない)。
                    .opacity(fullProgress)
                    .allowsHitTesting(fullProgress > 0.9)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(height: height, alignment: .top)
    }

    /// 後ろに見せる前後の写真。コンパクトは帯、広がると写真+日時+中身。
    private func peekCard(_ snap: PageSnapshot, progress: CGFloat, fullProgress: CGFloat, width: CGFloat, expandedHeight: CGFloat, topPad: CGFloat) -> some View {
        let reveal = min(abs(pageOffset) / 160, 1)
        // 文字は動かさないので、後ろの写真も手前と同じ大きさにそろえる(縦横比が違えば切り抜く)。
        let imageHeight = lerp(compactImageSize, expandedHeight, progress)
        let imageWidth = lerp(compactImageSize, width, progress)
        // 写真だけを先読みする。文字(日時・メモ)は、飛んで入れ替わったあとに切り替わる。
        return snap.image
            .resizable()
            .scaledToFill()
            .frame(width: imageWidth, height: imageHeight)
            .clipShape(RoundedRectangle(cornerRadius: lerp(24, 20, progress)))
            .padding(.horizontal, headerPadding)
            .padding(.top, topPad)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .scaleEffect(0.94 + 0.06 * reveal, anchor: .top)
            .opacity(0.4 + 0.6 * reveal)
            .allowsHitTesting(false)
    }

    /// 指を離した向きへ飛ばして消し、差し替えた次の写真を手前に入れる。
    private func flingAway(_ step: Int) {
        guard let onPage else { return }
        withAnimation(.easeIn(duration: 0.2)) {
            pageOffset = CGFloat(-step) * 520
            pageOpacity = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            onPage(step)
            scrollPosition.scrollTo(edge: .top)
            var instant = Transaction()
            instant.disablesAnimations = true
            // 後ろで見えていた写真と入れ替わるので、そのまま手前に出す(点滅させない)。
            // 次の文字はスワイプ中に出し終えているので、入れ替わっても濃さは変えない。
            withTransaction(instant) {
                pageOffset = 0
                pageOpacity = 1
                pageScale = 1
            }
        }
    }

    /// iOS 26 純正のガラスの丸ボタン(.glass + .circle)。サイズと押下の反応はシステムに任せる。
    private var closeButton: some View {
        Button {
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                detent = .compact
            }
        } label: {
            Image(systemName: "xmark")
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
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
                let w = value.translation.width, h = value.translation.height
                state = abs(w) > abs(h) * 1.5 ? 0 : h
            }
            .onEnded { value in
                // 横向きのドラッグは前後の写真への移動なので、段階は変えない。
                if abs(value.translation.width) > abs(value.translation.height) * 1.5 { return }
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

    private func headerHeight(progress: CGFloat, fullProgress: CGFloat, compact: CGFloat, imageHeight: CGFloat) -> CGFloat {
        let expanded = closeBarHeight * fullProgress + imageHeight + 24 + 12 + 12 + 40
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

/// 左右スワイプ中のカードの見た目: 横に動き、動いた量だけ下端を軸に傾く。
private struct PageCard: ViewModifier {
    var offset: CGFloat
    var opacity: CGFloat
    var scale: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .rotationEffect(.degrees(Double(offset) / 18), anchor: .bottom)
            .offset(x: offset)
            .opacity(opacity)
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
