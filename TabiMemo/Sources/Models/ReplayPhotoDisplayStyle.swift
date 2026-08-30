import Foundation

/// カメラが写真ピンに到達したとき、写真をどう見せるか。リプレイ画面内でその場に切り替えて見比べる。
enum ReplayPhotoDisplayStyle: String, CaseIterable, Identifiable {
    /// 地図を一時的に隠して写真を全画面カットインで見せる。
    case fullScreenCutIn
    /// 地図を背景に見せたまま、写真を大きめのカードでオーバーレイ表示する。
    case overlayCard
    /// 別オーバーレイを出さず、地図上の写真ピンをその場で強調表示するだけ。
    case pinEmphasis

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fullScreenCutIn: "全画面カットイン"
        case .overlayCard: "オーバーレイカード"
        case .pinEmphasis: "ピン強調のみ"
        }
    }

    /// このスタイルで写真到達時に追加でカメラを留める時間(秒)。
    var holdDuration: TimeInterval {
        switch self {
        case .fullScreenCutIn: 2.2
        case .overlayCard: 1.6
        case .pinEmphasis: 0.9
        }
    }
}
