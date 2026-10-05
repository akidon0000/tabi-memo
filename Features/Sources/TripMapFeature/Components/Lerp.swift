import CoreGraphics

/// `from` から `to` へ、`t`(0〜1)の割合だけ進めた値。
func lerp(_ from: CGFloat, _ to: CGFloat, _ t: CGFloat) -> CGFloat {
    from + (to - from) * t
}
