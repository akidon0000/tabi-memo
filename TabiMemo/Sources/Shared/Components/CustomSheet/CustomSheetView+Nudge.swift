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

    /// 全開の間、一定間隔でバーを下へ揺らして、下にスワイプで畳めることを伝える。
    func runNudgeLoop() async {
        barNudge = 0
        guard detent == .full else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(4))
            if Task.isCancelled { return }
            // 指で触れている間は揺らさない。
            if isTouching { continue }
            for offset: CGFloat in [10, 2, 8, 0] {
                if isTouching { break }
                withAnimation(.easeOut(duration: 0.12)) { barNudge = offset }
                try? await Task.sleep(for: .milliseconds(120))
            }
        }
    }
}
