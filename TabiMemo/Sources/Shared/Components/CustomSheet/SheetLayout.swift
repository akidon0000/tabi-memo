import CoreGraphics

/// パネルの各部の大きさ。画面の大きさ、いまの段階、ドラッグ量、スワイプ量から、1回の描画ごとに求める。
struct SheetLayout {
    /// 段階ごとのパネルの高さ。
    struct Heights {
        var compact: CGFloat
        var half: CGFloat
        var full: CGFloat
    }

    var heights: Heights
    var panelHeight: CGFloat
    var panelWidth: CGFloat
    /// コンパクト→ハーフで 0 → 1。
    var progress: CGFloat
    /// ハーフ→全開で 0 → 1。全開に近づくほど中身の背景を白くする。
    var fullProgress: CGFloat
    var margin: CGFloat
    var bottomMargin: CGFloat
    var expandedImageWidth: CGFloat
    /// 文字の位置に使う写真の高さ。スワイプ中は、スワイプ先の写真の高さへ寄っていく。
    var expandedImageHeight: CGFloat
    /// いま表示している写真そのものの高さ。
    var ownImageHeight: CGFloat
    /// スワイプ先の写真の高さ。
    var nextImageHeight: CGFloat
}
