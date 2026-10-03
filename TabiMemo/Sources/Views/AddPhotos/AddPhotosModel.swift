import CoreLocation
import Observation
import PhotosUI
import SwiftData
import SwiftUI

/// 保存前の1枚ぶんの入力状態。
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
    var coordinate: CLLocationCoordinate2D?
    var isLocationManual = false
    var title = ""
    var memo = ""
    var suggestion: Suggestion = .idle

    var isReady: Bool { imageData != nil && coordinate != nil }
}

/// 複数枚の追加の流れ全体。ピッカーで選んだ写真を読み込み、まとめて保存する。
@Observable
final class AddPhotosModel: Identifiable {
    let id = UUID()
    var drafts: [PhotoDraft]
    var currentID: PhotoDraft.ID?

    /// 位置の初期値を求める材料(すでにある写真)と、それも無いときに使う地図の中心。
    private let existingPoints: [PhotoLocationGuess.Point]
    let fallbackCenter: CLLocationCoordinate2D

    init(count: Int, existingPoints: [PhotoLocationGuess.Point], fallbackCenter: CLLocationCoordinate2D) {
        self.existingPoints = existingPoints
        self.fallbackCenter = fallbackCenter
        let drafts = (0..<count).map { _ in PhotoDraft() }
        self.drafts = drafts
        currentID = drafts.first?.id
    }

    var canSave: Bool { !drafts.isEmpty && drafts.allSatisfy(\.isReady) }

    var currentIndex: Int { drafts.firstIndex { $0.id == currentID } ?? 0 }

    /// 選んだ写真を順に読み込む。読めたページから埋まり、AI の提案は表示中とその次のページだけ先に作る。
    func load(_ items: [PhotosPickerItem]) async {
        for (draft, item) in zip(drafts, items) {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                draft.loadFailed = true
                continue
            }
            let metadata = PhotoMetadataReader.read(from: data)
            draft.imageData = data
            if let date = metadata.takenAt {
                draft.takenAt = date
                draft.hasMetadataDate = true
            }
            draft.coordinate = metadata.coordinate
        }
        prefetchSuggestions()
    }

    /// 位置が決まっている写真(すでにあるものと、この流れで確定したもの)から求めた、地図の初期位置。
    func initialCenter(for draft: PhotoDraft) -> CLLocationCoordinate2D {
        let batch = drafts.compactMap { other in
            other.coordinate.map { PhotoLocationGuess.Point(date: other.takenAt, coordinate: $0) }
        }
        return PhotoLocationGuess.center(for: draft.takenAt, among: existingPoints + batch) ?? fallbackCenter
    }

    func prefetchSuggestions() {
        let index = currentIndex
        for draft in drafts[index...].prefix(2) {
            requestSuggestion(for: draft)
        }
    }

    private func requestSuggestion(for draft: PhotoDraft) {
        guard case .idle = draft.suggestion, let data = draft.imageData else { return }
        draft.suggestion = .loading
        Task {
            if let result = await PhotoSuggestionService.suggest(from: data) {
                draft.suggestion = .ready(result)
            } else {
                draft.suggestion = .unavailable
            }
        }
    }

    /// 読み込みに失敗した写真を外す。
    func remove(_ draft: PhotoDraft) {
        drafts.removeAll { $0.id == draft.id }
        if currentID == draft.id { currentID = drafts.first?.id }
    }

    func save(into trip: Trip, context: ModelContext) {
        for draft in drafts {
            guard let data = draft.imageData, let coordinate = draft.coordinate else { continue }
            let photo = TripPhoto(
                imageData: data,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                takenAt: draft.takenAt,
                isLocationManuallyPlaced: draft.isLocationManual,
                title: draft.title,
                memo: draft.memo
            )
            context.insert(photo)
            photo.trip = trip
        }
        try? context.save()
    }
}
