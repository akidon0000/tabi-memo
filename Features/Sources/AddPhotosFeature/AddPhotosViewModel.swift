import Domain
import Foundation
import Observation
import PhotosUI
import SwiftUI

/// 複数枚の追加の流れ全体。ピッカーで選んだ写真を読み込み、まとめて保存する。
@MainActor
@Observable
public final class AddPhotosViewModel {
    var drafts: [PhotoDraft]
    var currentID: PhotoDraft.ID?
    /// 並べ替え画面の並び(すでにある写真 + 新しい写真)。
    var entries: [ReorderEntry] = []
    /// 位置の初期値を求める材料が無いときに使う、地図の中心。
    let fallbackCenter: Coordinate
    /// 地図の長押しで指定された位置。あれば、すべての写真の位置をここにする(写真の位置情報より優先)。
    private let placement: Coordinate?

    private let trip: Trip
    private let readMetadata: ReadPhotoMetadataUseCase
    private let suggestText: SuggestPhotoTextUseCase
    private let addPhotos: AddPhotosUseCase

    public init(
        count: Int,
        trip: Trip,
        fallbackCenter: Coordinate,
        placement: Coordinate? = nil,
        readMetadata: ReadPhotoMetadataUseCase,
        suggestText: SuggestPhotoTextUseCase,
        addPhotos: AddPhotosUseCase
    ) {
        self.trip = trip
        self.fallbackCenter = fallbackCenter
        self.placement = placement
        self.readMetadata = readMetadata
        self.suggestText = suggestText
        self.addPhotos = addPhotos
        let drafts = (0..<count).map { _ in PhotoDraft() }
        for draft in drafts where placement != nil {
            draft.coordinate = placement
            draft.isLocationManual = true
        }
        self.drafts = drafts
        currentID = drafts.first?.id
    }

    var isMultiple: Bool { drafts.count > 1 }

    var canSave: Bool { !drafts.isEmpty && drafts.allSatisfy(\.isReady) }

    var currentIndex: Int { drafts.firstIndex { $0.id == currentID } ?? 0 }

    /// 選んだ写真を順に読み込む。読めたページから埋まり、AI の提案は表示中とその次のページだけ先に作る。
    func load(_ items: [PhotosPickerItem]) async {
        for (draft, item) in zip(drafts, items) {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                draft.loadFailed = true
                continue
            }
            let metadata = readMetadata.execute(imageData: data)
            draft.imageData = data
            if let date = metadata.takenAt {
                draft.takenAt = date
                draft.hasMetadataDate = true
            }
            if placement == nil { draft.coordinate = metadata.coordinate }
        }
        prefetchSuggestions()
    }

    /// 位置が決まっている写真(すでにあるものと、この流れで確定したもの)から求めた、地図の初期位置。
    func initialCenter(for draft: PhotoDraft) -> Coordinate {
        let existing = trip.activePhotos.map { PhotoLocationGuess.Point(date: $0.takenAt, coordinate: $0.coordinate) }
        let batch = drafts.compactMap { other in
            other.coordinate.map { PhotoLocationGuess.Point(date: other.takenAt, coordinate: $0) }
        }
        return PhotoLocationGuess.center(for: draft.takenAt, among: existing + batch) ?? fallbackCenter
    }

    func prefetchSuggestions() {
        guard !drafts.isEmpty else { return }
        for draft in drafts[currentIndex...].prefix(2) {
            requestSuggestion(for: draft)
        }
    }

    /// 読み込みに失敗した写真を外す。
    func remove(_ draft: PhotoDraft) {
        drafts.removeAll { $0.id == draft.id }
        if currentID == draft.id { currentID = drafts.first?.id }
    }

    /// 並べ替え画面に入る。最初の並びは日時の順(動かすまで日時が変わらないように)。
    func prepareReorder() {
        entries = (trip.activePhotos.map(ReorderEntry.existing) + drafts.map(ReorderEntry.new))
            .sorted { $0.takenAt < $1.takenAt }
    }

    /// 並べ替え画面で、各行に当てはまる日時。いまの日時を古い順に並べ、並びの順に割り当てる。
    var assignedDates: [Date] { entries.map(\.takenAt).sorted() }

    /// まとめて保存する。並べ替え画面を通ったときは、その並びで日時を割り当て直す。
    func save() {
        let newPhotos = drafts.compactMap(\.newPhoto)
        try? addPhotos.execute(newPhotos, order: entries.map(\.id), to: trip)
    }

    private func requestSuggestion(for draft: PhotoDraft) {
        guard case .idle = draft.suggestion, let data = draft.imageData else { return }
        draft.suggestion = .loading
        Task {
            if let result = await suggestText.execute(imageData: data) {
                draft.suggestion = .ready(result)
            } else {
                draft.suggestion = .unavailable
            }
        }
    }
}
