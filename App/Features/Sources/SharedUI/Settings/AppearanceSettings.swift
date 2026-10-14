import SwiftUI

/// 見た目の選択肢。実機で見比べて決めるために、案をアプリ内の設定で切り替えられるようにしてある(決めたら、使わない案を消す)。
/// 保存は `@AppStorage`(UserDefaults)。キーは `AppearanceKey` にまとめる。
public enum AppearanceKey {
    public static let tripListStyle = "appearance.tripListStyle"
    public static let tripListOrder = "appearance.tripListOrder"
    public static let backButton = "appearance.backButton"
    public static let addChoice = "appearance.addChoice"
    public static let shutter = "appearance.shutter"
    public static let doneButton = "appearance.doneButton"
    public static let captureCount = "appearance.captureCount"
}

public enum TripListStyle: String, CaseIterable, Identifiable {
    case list, cards, grid
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .list: "リスト"
        case .cards: "カード"
        case .grid: "グリッド"
        }
    }
}

public enum TripListOrder: String, CaseIterable, Identifiable {
    case newest, period, name
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .newest: "作った日の新しい順"
        case .period: "旅の日付の新しい順"
        case .name: "名前順"
        }
    }
}

public enum BackButtonPlacement: String, CaseIterable, Identifiable {
    case topLeading, inMenu
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .topLeading: "左上の丸いボタン"
        case .inMenu: "「…」メニューの中"
        }
    }
}

public enum AddChoiceStyle: String, CaseIterable, Identifiable {
    case actionSheet, bottomSheet
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .actionSheet: "下から出るメニュー"
        case .bottomSheet: "大きな2ボタンの小さなシート"
        }
    }
}

public enum ShutterStyle: String, CaseIterable, Identifiable {
    case classic, glass
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .classic: "白い輪(標準のカメラ風)"
        case .glass: "ガラスの丸"
        }
    }
}

public enum DoneButtonPlacement: String, CaseIterable, Identifiable {
    case bottomTrailing, topTrailing
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .bottomTrailing: "右下(シャッターの横)"
        case .topTrailing: "右上"
        }
    }
}

public enum CaptureCountStyle: String, CaseIterable, Identifiable {
    case thumbnail, badge
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .thumbnail: "最後に撮った写真のサムネイル"
        case .badge: "枚数の数字だけ"
        }
    }
}
