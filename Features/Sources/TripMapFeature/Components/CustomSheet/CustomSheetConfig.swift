import SwiftUI

/// `CustomSheetView` の見た目を決める設定。
struct CustomSheetConfig {
    var headerTint: Color = .yellow
    /// 一番小さく畳んだとき(コンパクト)のパネルの高さ。
    var smallestDetentHeight: CGFloat = 64
    /// ハーフ以上のときのヘッダー画像の高さ。
    var expandedImageHeight: CGFloat = 240
}
