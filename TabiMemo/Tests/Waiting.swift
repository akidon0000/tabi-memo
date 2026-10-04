import Foundation

/// 条件が成り立つまで待つ(ViewModel がストリームを受け取るのを待つのに使う)。1秒で諦める。
@MainActor
func waitUntil(_ condition: () -> Bool) async {
    for _ in 0..<200 {
        if condition() { return }
        try? await Task.sleep(for: .milliseconds(5))
    }
}
