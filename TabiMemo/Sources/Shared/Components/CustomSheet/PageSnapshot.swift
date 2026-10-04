import SwiftUI

/// 前後の写真の見た目。スワイプ中に後ろへ先読みして描く。
struct PageSnapshot {
    var title: String
    var image: Image
    var aspectRatio: CGFloat
    var content: AnyView
}
