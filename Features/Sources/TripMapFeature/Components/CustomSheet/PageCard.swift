import SwiftUI

/// 左右スワイプ中のカードの見た目: 横に動き、傾けるときは動いた量だけ下端を軸に傾く。
struct PageCard: ViewModifier {
    var offset: CGFloat
    var scale: CGFloat
    /// ハーフでは傾ける(Tinder 風)。全開ではページごと平行に滑らせるので傾けない。
    var rotates: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotates ? Double(offset) / 18 : 0), anchor: .bottom)
            .offset(x: offset)
    }
}
