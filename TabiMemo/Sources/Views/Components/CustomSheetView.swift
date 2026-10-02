import SwiftUI

/// Config
struct CustomSheetConfig {
    var headerCornerRadius: CGFloat = 20
    var headerTint: Color = .yellow
    var largestDetentHeight: CGFloat = .infinity
    var smallestDetentHeight: CGFloat = 80
    var expandedImageHeight: CGFloat = 240
}

struct CustomSheetView<Content: View>: View {
    @Binding var config: CustomSheetConfig
    var title: String
    var caption: String
    var headerImage: Image
    /// 指定すると、コンパクト時にバナーの右(枠の外)へ円形の追加ボタンを出す。ヘッダーが開くと消える。
    var onAdd: (() -> Void)?
    @ViewBuilder var content: Content

    @State private var sheetHeight: CGFloat = 0
    /// nil の間は常にコンパクト(最新の config から計算)を選択扱いにする。
    @State private var selectedDetent: PresentationDetent?
    @State private var scrollOffset: CGFloat = 0

    init(
        config: Binding<CustomSheetConfig>,
        title: String,
        caption: String,
        headerImage: Image,
        onAdd: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        _config = config
        self.title = title
        self.caption = caption
        self.headerImage = headerImage
        self.onAdd = onAdd
        self.content = content()
    }

    private let compactImageSize: CGFloat = 48
    private let horizontalPadding: CGFloat = 16
    private let addButtonSize: CGFloat = 56
    private let addButtonGap: CGFloat = 10

    var body: some View {
        GeometryReader { proxy in
            let progress = expandProgress(for: proxy.size.height)
            let headerHeight = headerHeight(progress: progress)

            ZStack(alignment: .top) {
                ScrollView(.vertical) {
                    content
                        .padding(.top, headerHeight)
                }
                // シート自体の背景は透明にしてあるので、開くにつれて中身の背景を出す。
                .background(Color(.systemBackground).opacity(min(progress * 4, 1)))
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    max(geometry.contentOffset.y + geometry.contentInsets.top, 0)
                } action: { _, newValue in
                    scrollOffset = newValue
                }

                header(progress: progress, height: headerHeight, bottomInset: proxy.safeAreaInsets.bottom)
            }
            .onChange(of: proxy.size.height, initial: true) { _, newValue in
                sheetHeight = newValue
            }
        }
        .presentationDetents([smallestDetent, centerDetent, largestDetent], selection: detentSelection)
        .presentationBackground(.clear)
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled(upThrough: centerDetent))
        .interactiveDismissDisabled()
    }

    /// 開いた直後はコンパクト(一番小さい高さ)から始める。
    private var detentSelection: Binding<PresentationDetent> {
        Binding(
            get: { selectedDetent ?? smallestDetent },
            set: { selectedDetent = $0 }
        )
    }

    // MARK: - Header

    private func header(progress: CGFloat, height: CGFloat, bottomInset: CGFloat) -> some View {
        // 全開後のスクロール量で、画像を最大で半分まで縮める。
        let collapse = min(scrollOffset / 120, 1) * progress
        let imageHeight = lerp(compactImageSize, config.expandedImageHeight * (1 - 0.5 * collapse), progress)
        let imageWidth = lerp(compactImageSize, expandedImageWidth, progress)
        let radius = lerp(10, config.headerCornerRadius, progress)
        // 畳み側と展開側のタイトルを重ならないようにクロスフェードする。
        let compactOpacity = max(1 - progress * 4, 0)
        let expandedOpacity = max(progress * 2 - 1, 0)
        // 追加ボタンの分だけバナーを左に縮める。ヘッダーが開くにつれて 0 に戻る。
        let reserve = onAdd == nil ? 0 : (addButtonSize + addButtonGap) * max(1 - progress * 3, 0)
        let addOpacity = max(1 - progress * 4, 0)

        return ZStack(alignment: .topLeading) {
            headerImage
                .resizable()
                .scaledToFill()
                .frame(width: imageWidth, height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: radius))

            titleBlock(fontSize: 16)
                .frame(height: compactImageSize, alignment: .center)
                .padding(.leading, compactImageSize + 12)
                .padding(.trailing, 12)
                .opacity(compactOpacity)

            titleBlock(fontSize: 24)
                .padding(.top, imageHeight + 12)
                .opacity(expandedOpacity)
        }
        .padding(.leading, horizontalPadding)
        .padding(.trailing, horizontalPadding + reserve)
        .padding(.top, lerp(16, 24, progress))
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .topLeading)
        .background(alignment: .top) {
            // 畳んだ状態ではシート下端(ホームインジケーター側)までヘッダーの色で埋める。
            // 畳むと全体が丸いバナー、開くと上の角だけ丸いヘッダーになる。
            let corner = lerp(40, 36, progress)
            UnevenRoundedRectangle(
                topLeadingRadius: corner,
                bottomLeadingRadius: lerp(40, 0, progress),
                bottomTrailingRadius: lerp(40, 0, progress),
                topTrailingRadius: corner
            )
            .fill(config.headerTint.opacity(0.25 + 0.15 * progress))
            .background(.regularMaterial, in: UnevenRoundedRectangle(
                topLeadingRadius: corner,
                bottomLeadingRadius: lerp(40, 0, progress),
                bottomTrailingRadius: lerp(40, 0, progress),
                topTrailingRadius: corner
            ))
            .padding(.trailing, reserve)
            .padding(.bottom, -bottomInset * (1 - progress))
        }
        .overlay(alignment: .topTrailing) {
            if let onAdd {
                addButton(action: onAdd)
                    .opacity(addOpacity)
                    .allowsHitTesting(addOpacity > 0.5)
                    .padding(.top, (height - addButtonSize) / 2)
            }
        }
    }

    private func addButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: addButtonSize, height: addButtonSize)
                .background(config.headerTint.opacity(0.25), in: .circle)
                .background(.regularMaterial, in: .circle)
        }
        .accessibilityLabel("写真を追加")
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

    // MARK: - Geometry

    private var expandedImageWidth: CGFloat {
        max(windowSize.width - horizontalPadding * 2, compactImageSize)
    }

    private func headerHeight(progress: CGFloat) -> CGFloat {
        let collapse = min(scrollOffset / 120, 1) * progress
        let compact = config.smallestDetentHeight
        let expanded = config.expandedImageHeight * (1 - 0.5 * collapse) + 24 + 12 + 12 + 40
        return lerp(compact, expanded, progress)
    }

    private func expandProgress(for height: CGFloat) -> CGFloat {
        // ハーフモーダルの高さで、すでにヘッダーが全開(progress = 1)になる。
        let range = centerHeight - config.smallestDetentHeight
        guard range > 0 else { return 1 }
        return min(max((height - config.smallestDetentHeight) / range, 0), 1)
    }

    private var centerHeight: CGFloat {
        Self.centerHeight(for: config)
    }

    private var centerDetent: PresentationDetent {
        Self.centerDetent(for: config)
    }

    private static func centerHeight(for config: CustomSheetConfig) -> CGFloat {
        let maxHeight = config.largestDetentHeight.isFinite
            ? config.largestDetentHeight
            : screenSize.height - 10
        return (maxHeight + config.smallestDetentHeight) / 2
    }

    private static func centerDetent(for config: CustomSheetConfig) -> PresentationDetent {
        .height(centerHeight(for: config))
    }

    private var smallestDetent: PresentationDetent {
        .height(config.smallestDetentHeight)
    }

    private var largestDetent: PresentationDetent {
        config.largestDetentHeight.isFinite ? .height(config.largestDetentHeight) : .large
    }

    private var windowSize: CGSize { Self.screenSize }

    private static var screenSize: CGSize {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
        return scene?.screen.bounds.size ?? CGSize(width: 390, height: 844)
    }

    private func lerp(_ from: CGFloat, _ to: CGFloat, _ t: CGFloat) -> CGFloat {
        from + (to - from) * t
    }
}

#Preview {
    @Previewable @State var config = CustomSheetConfig()
    Color.gray.opacity(0.2)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            CustomSheetView(
                config: $config,
                title: "代々木公園入口",
                caption: "2026年10月2日 18:11",
                headerImage: Image(systemName: "photo")
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
