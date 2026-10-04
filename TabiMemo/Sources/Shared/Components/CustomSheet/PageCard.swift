import SwiftUI

/// 左右スワイプ中のカードの見た目: 横に動き、動いた量だけ下端を軸に傾く。
struct PageCard: ViewModifier {
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
