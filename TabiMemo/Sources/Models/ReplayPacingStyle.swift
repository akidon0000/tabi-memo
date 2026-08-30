import Foundation

/// リプレイのカメラが軌跡をなぞる速度をどう配分するか。
/// Settings画面のトグルでアプリ全体のデフォルトとして切り替える。
enum ReplayPacingStyle: String, CaseIterable, Identifiable {
    /// 写真と写真の間の実経過時間が長い区間は速く通過し、短時間に密に撮った区間はゆっくり見せる。
    case timeBased
    /// 距離あたりの写真密度が高い区間はゆっくり、低い区間は速く通過する。実経過時間は考慮しない。
    case densityBased

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .timeBased: "時間ベース"
        case .densityBased: "密度ベース"
        }
    }
}
