import AddPhotosFeature
import Domain
import EditPhotoFeature
import PhotoListFeature
import RecentlyDeletedFeature
import SharedUI
import Observation

/// 地図画面の状態。表示中のトリップと、パネルに出している写真を持つ。
@MainActor
@Observable
public final class TripMapViewModel {
    private(set) var trip: Trip?
    /// 保存先から最初の値を受け取ったら true。それまでは「トリップがありません」を出さない。
    private(set) var hasLoaded = false
    /// パネルに表示中の写真。別のピンをタップしても、パネルは閉じずに中身だけ差し替える。
    var selectedPhotoID: Photo.ID?
    /// 写真を撮影順に結ぶ線(道なりの経路と、経路編集モード)。
    let route: RouteViewModel

    private var hasPurged = false
    private var hasSelectedInitially = false
    private let observeCurrentTrip: ObserveCurrentTripUseCase
    private let purgeExpiredPhotos: PurgeExpiredPhotosUseCase
    private let removePhoto: RemovePhotoUseCase

    public init(
        observeCurrentTrip: ObserveCurrentTripUseCase,
        purgeExpiredPhotos: PurgeExpiredPhotosUseCase,
        removePhoto: RemovePhotoUseCase,
        route: RouteViewModel
    ) {
        self.observeCurrentTrip = observeCurrentTrip
        self.purgeExpiredPhotos = purgeExpiredPhotos
        self.removePhoto = removePhoto
        self.route = route
    }

    /// 選んでいる写真の最新の内容。取り除かれたり消えたりしたら nil(パネルが閉じる)。
    var selectedPhoto: Photo? {
        guard let selectedPhotoID else { return nil }
        return trip?.activePhotos.first { $0.id == selectedPhotoID }
    }

    /// 画面が出ている間、トリップの最新の内容を受け取り続ける。最初の1回だけ、保持期間を過ぎた写真を消す。
    func start() async {
        for await trip in observeCurrentTrip.execute() {
            self.trip = trip
            hasLoaded = true
            guard let trip else { continue }
            selectFirstPhotoOnce(in: trip)
            route.refresh(for: trip)
            if !hasPurged {
                hasPurged = true
                try? purgeExpiredPhotos.execute(in: trip)
            }
        }
    }

    /// 開いたとき、撮影順で最初の写真を選んでおく。起動中に1回だけ(取り除いたあとに自動で選び直さない)。
    private func selectFirstPhotoOnce(in trip: Trip) {
        guard !hasSelectedInitially else { return }
        hasSelectedInitially = true
        selectedPhotoID = trip.activePhotos.first?.id
    }

    func select(_ photo: Photo) {
        selectedPhotoID = photo.id
    }

    /// 撮影順で隣の写真(step: 前 -1 / 次 +1)。端なら nil。
    func neighbor(_ step: Int, of photo: Photo) -> Photo? {
        trip?.neighbor(step, of: photo.id)
    }

    /// 選んでいる写真を「最近取り除いた項目」へ移し、隣の写真(次があれば次、なければ前)を選ぶ。
    /// - Returns: 新しく選んだ写真。最後の1枚だったときは nil(パネルが閉じる)。
    @discardableResult
    func removeSelectedPhoto() -> Photo? {
        guard let photo = selectedPhoto else { return nil }
        let next = neighbor(1, of: photo) ?? neighbor(-1, of: photo)
        try? removePhoto.execute(photoID: photo.id)
        selectedPhotoID = next?.id
        return next
    }
}
