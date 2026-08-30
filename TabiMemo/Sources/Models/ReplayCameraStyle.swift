import Foundation

/// リプレイ中にカメラをどう動かすか。リプレイ画面内でその場に切り替えて見比べる。
enum ReplayCameraStyle: String, CaseIterable, Identifiable {
    /// 真上からの俯瞰。軌跡に沿って地図がスライドする。
    case topDown
    /// 斜め上から進行方向を向いて追いかける、ドローン視点。
    case followDrone
    /// 進行方向に正対する、低めの一人称に近い視点。
    case firstPerson

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .topDown: "俯瞰"
        case .followDrone: "追従3D"
        case .firstPerson: "一人称"
        }
    }

    var pitch: Double {
        switch self {
        case .topDown: 0
        case .followDrone: 60
        case .firstPerson: 78
        }
    }

    var distance: Double {
        switch self {
        case .topDown: 900
        case .followDrone: 320
        case .firstPerson: 130
        }
    }

    /// 俯瞰は北を上に固定し、それ以外は進行方向にheadingを合わせる。
    var followsTravelHeading: Bool {
        self != .topDown
    }
}
