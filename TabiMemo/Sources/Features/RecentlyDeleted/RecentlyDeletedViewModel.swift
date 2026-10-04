import Domain
import Foundation
import Observation

/// 「最近取り除いた項目」の状態。保持期間のあいだ、元に戻すか、完全に削除できる。
@MainActor
@Observable
final class RecentlyDeletedViewModel {
    private(set) var trip: Trip?

    private var hasPurged = false
    private let tripID: Trip.ID
    private let observeTrip: ObserveTripUseCase
    private let restorePhoto: RestorePhotoUseCase
    private let deletePhotoPermanently: DeletePhotoPermanentlyUseCase
    private let purgeExpiredPhotos: PurgeExpiredPhotosUseCase

    init(
        tripID: Trip.ID,
        observeTrip: ObserveTripUseCase,
        restorePhoto: RestorePhotoUseCase,
        deletePhotoPermanently: DeletePhotoPermanentlyUseCase,
        purgeExpiredPhotos: PurgeExpiredPhotosUseCase
    ) {
        self.tripID = tripID
        self.observeTrip = observeTrip
        self.restorePhoto = restorePhoto
        self.deletePhotoPermanently = deletePhotoPermanently
        self.purgeExpiredPhotos = purgeExpiredPhotos
    }

    /// 取り除いた写真。新しく取り除いたものが先頭。
    var photos: [Photo] { trip?.removedPhotos ?? [] }

    /// 画面が出ている間、トリップの最新の内容を受け取り続ける。最初の1回だけ、保持期間を過ぎた写真を消す。
    func start() async {
        for await trip in observeTrip.execute(tripID: tripID) {
            self.trip = trip
            if let trip, !hasPurged {
                hasPurged = true
                try? purgeExpiredPhotos.execute(in: trip)
            }
        }
    }

    func restore(_ photo: Photo) {
        try? restorePhoto.execute(photoID: photo.id)
    }

    func deletePermanently(_ photo: Photo) {
        try? deletePhotoPermanently.execute(photoID: photo.id)
    }
}
