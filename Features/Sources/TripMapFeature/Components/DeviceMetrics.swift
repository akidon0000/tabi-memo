import UIKit

/// 端末の画面の寸法のうち、SwiftUI のレイアウトからは取れないもの。
enum DeviceMetrics {
    /// 上のセーフエリアの高さ。親が ignoresSafeArea() だと GeometryProxy から取れないので、ウィンドウから読む。
    static var windowSafeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets.top ?? 0
    }

    /// 端末の画面角の半径。公開 API が無いため非公開キーで読み、取れなければ近い値を使う(ADR 0004)。
    static var cornerRadius: CGFloat {
        let screen = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen
        let value = (screen?.value(forKey: "_displayCornerRadius") as? CGFloat) ?? 0
        return value > 0 ? value : 55
    }
}
