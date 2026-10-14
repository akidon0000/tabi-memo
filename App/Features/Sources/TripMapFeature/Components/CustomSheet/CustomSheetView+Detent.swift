import SwiftUI

extension CustomSheetView {
    /// バーのタップ: コンパクト → ハーフ → 全開。全開では、閉じるボタンの代わりに、畳んでコンパクトへ戻す。
    func advanceDetent() {
        switch detent {
        case .compact: withAnimation(.spring(duration: 0.4, bounce: 0.15)) { detent = .half }
        case .half: withAnimation(.spring(duration: 0.4, bounce: 0.15)) { detent = .full }
        case .full: collapse()
        }
    }

    /// 畳んでコンパクトに戻す(全開でバーをタップしたとき)。
    func collapse() {
        withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
            detent = .compact
        }
    }
}
