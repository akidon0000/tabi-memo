import Domain
import Foundation
import Observation

/// 保存前の1枚ぶんの入力状態。
@MainActor
@Observable
final class PhotoDraft: Identifiable {
    enum Suggestion {
        case idle, loading, ready(PhotoSuggestion), unavailable
    }

    let id = UUID()
    /// 読み込み中は nil。
    var imageData: Data?
    var loadFailed = false
    var takenAt: Date = .now
    /// 日時が写真のデータから取れたか。取れなければ画面に「現在時刻を入れています」と出す。
    var hasMetadataDate = false
    var coordinate: Coordinate?
    var isLocationManual = false
    var title = ""
    var memo = ""
    var suggestion: Suggestion = .idle

    var isReady: Bool { imageData != nil && coordinate != nil }

    /// 保存する形。画像か位置がまだ無ければ nil。
    var newPhoto: NewPhoto? {
        guard let imageData, let coordinate else { return nil }
        return NewPhoto(
            id: id,
            imageData: imageData,
            coordinate: coordinate,
            takenAt: takenAt,
            isLocationManuallyPlaced: isLocationManual,
            title: title,
            memo: memo
        )
    }
}
