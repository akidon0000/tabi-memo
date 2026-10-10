import Domain
import Foundation
import Observation

/// 写真の一覧画面の状態。並べ替えと取り除く操作を受け持つ。
@MainActor
@Observable
public final class PhotoListViewModel {
    private(set) var trip: Trip?

    private let tripID: Trip.ID
    private let observeTrip: ObserveTripUseCase
    private let reorderPhotos: ReorderPhotosUseCase
    private let removePhoto: RemovePhotoUseCase

    public init(tripID: Trip.ID, observeTrip: ObserveTripUseCase, reorderPhotos: ReorderPhotosUseCase, removePhoto: RemovePhotoUseCase) {
        self.tripID = tripID
        self.observeTrip = observeTrip
        self.reorderPhotos = reorderPhotos
        self.removePhoto = removePhoto
    }

    /// 地図に出ている写真。撮影日時の順。
    var photos: [Photo] { trip?.activePhotos ?? [] }

    func start() async {
        for await trip in observeTrip.execute(tripID: tripID) {
            self.trip = trip
        }
    }

    /// リストのドラッグで並べ替えたとき。
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        guard let trip else { return }
        var order = photos.map(\.id)
        order.move(fromOffsets: source, toOffset: destination)
        try? reorderPhotos.execute(order: order, in: trip)
    }

    /// グリッドで、`id` の写真を `target` のサムネイルへ落としたとき。
    /// - Returns: 並べ替えたら true(ドロップを受け付けた)。
    @discardableResult
    func move(_ id: Photo.ID, to target: Photo) -> Bool {
        guard let trip, photos.contains(where: { $0.id == id }) else { return false }
        let order = PhotoOrdering.moving(id, to: target.id, in: photos.map(\.id))
        try? reorderPhotos.execute(order: order, in: trip)
        return true
    }

    func remove(_ photo: Photo) {
        try? removePhoto.execute(photoID: photo.id)
    }
}
