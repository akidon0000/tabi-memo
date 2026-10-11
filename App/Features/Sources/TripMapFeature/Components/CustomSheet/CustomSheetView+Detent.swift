import SwiftUI

extension CustomSheetView {
    /// バーのタップ: コンパクト → ハーフ → 全開。全開では何もしない(畳むのは閉じるボタンやドラッグ)。
    func advanceDetent() {
        let next: Detent? = switch detent {
        case .compact: .half
        case .half: .full
        case .full: nil
        }
        guard let next else { return }
        withAnimation(.spring(duration: 0.4, bounce: 0.15)) { detent = next }
    }

    /// 畳んでコンパクトに戻す(閉じるボタン、全開で下へ引いたとき)。
    func collapse() {
        withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
            detent = .compact
        }
    }
}
