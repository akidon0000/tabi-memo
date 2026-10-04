import SwiftUI

/// 地図の上に重ねて使う下部パネル。システムのシートではなく自前で描くので、
/// コンパクト時はバナーと円形の追加ボタンを完全に別のビューとして横並びにできる。
///
/// ファイルの分け方: 大きさの計算は +Layout、パネル本体は +Panel、写真とタイトルは +Header、
/// ボタン類は +Controls、ドラッグとスワイプは +Gestures、全開の揺らしは +Nudge。
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
    /// 編集・削除ボタン(ハーフ・全開で、写真の右下に出す)。onEdit が nil ならボタンを出さない。
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    /// 全開への進み具合(0〜1)。呼び出し側が、全開で消したい要素(右上の「…」)の濃さに使う。
    var onFullProgressChange: ((CGFloat) -> Void)?
    @ViewBuilder var content: Content

    enum Detent {
        case compact, half, full
    }

    // 別ファイルの extension から触るので private にしない。
    @State var detent: Detent = .compact
    @GestureState var dragTranslation: CGFloat = 0
    @State var scrollOffset: CGFloat = 0
    @State var barNudge: CGFloat = 0
    @State var pageOffset: CGFloat = 0
    @State var pageOpacity: CGFloat = 1
    @State var pageScale: CGFloat = 1
    /// 入れ替わった直後の文字の濃さ(0→1)。
    @State var textReveal: CGFloat = 1
    @State var isSwiping = false
    @State var peekStep = 1
    @State var scrollPosition = ScrollPosition(edge: .top)
    /// 指がヘッダーに触れている間 true。揺らしの判定に使う(task から読めるよう @State に写す)。
    @GestureState var isPressing = false
    @State var isTouching = false

    let compactImageSize: CGFloat = 40
    let headerPadding: CGFloat = 16
    /// 追加ボタンはコンパクトのバナーと同じ高さの円にする。
    var addButtonSize: CGFloat { config.smallestDetentHeight }
    let addButtonGap: CGFloat = 10
    /// 広がったときに写真の上へ確保する、×ボタンの行の高さ。
    let closeBarHeight: CGFloat = 44
    let compactMargin: CGFloat = 16
    let actionButtonHeight: CGFloat = 40
    /// 全開の×。中心は右上の「…」(44pt)と同じ位置にそろえる。
    let closeButtonSize: CGFloat = 28
    /// 全開の上の行(バーと×)を置く、パネル上端からの距離。
    let closeRowTop: CGFloat = 8
    let expandedMargin: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            let layout = layout(in: proxy.size)

            ZStack(alignment: .bottomLeading) {
                panel(layout)
                    .padding(.leading, layout.margin)
                    .padding(.bottom, layout.bottomMargin)

                // 広がるにつれて薄く小さくして消す。ガラスの opacity が効くよう、パネルとは別のビューにしてある。
                if let onAdd, layout.progress < 1 {
                    let fade = 1 - layout.progress
                    addButton(action: onAdd)
                        .opacity(fade)
                        .scaleEffect(0.6 + 0.4 * fade)
                        .allowsHitTesting(layout.progress < 0.3)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, layout.margin)
                        .padding(.bottom, layout.bottomMargin)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .onChange(of: layout.fullProgress) { _, value in onFullProgressChange?(value) }
            .task(id: detent) { await runNudgeLoop() }
            .onChange(of: isPressing) { _, pressing in
                isTouching = pressing
                if pressing { withAnimation(.easeOut(duration: 0.1)) { barNudge = 0 } }
            }
            // 全開のときは、上のセーフエリア(ステータスバー側)も白にする。
            .overlay(alignment: .top) {
                Color(.systemBackground)
                    .frame(height: DeviceMetrics.windowSafeAreaTop)
                    .opacity(layout.fullProgress)
                    .allowsHitTesting(false)
            }
        }
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
                onAdd: {},
                content: {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(0..<20) { index in
                            Text("行 \(index)")
                        }
                    }
                    .padding()
                }
            )
        }
}
