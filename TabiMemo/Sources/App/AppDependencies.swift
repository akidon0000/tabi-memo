import DataLayer
import Domain
import Observation

/// 依存の組み立て(Composition Root)。Repository と Service をここで作り、UseCase を通して各画面の ViewModel に渡す。
/// View は `@Environment(AppDependencies.self)` から `makeXxxViewModel` を呼んで、子画面を作る。
@MainActor
@Observable
final class AppDependencies {
    @ObservationIgnored private let tripRepository: any TripRepository
    @ObservationIgnored private let photoRepository: any PhotoRepository
    @ObservationIgnored private let metadataReader: any PhotoMetadataReading
    @ObservationIgnored private let suggester: any PhotoSuggesting

    init(
        tripRepository: any TripRepository,
        photoRepository: any PhotoRepository,
        metadataReader: any PhotoMetadataReading,
        suggester: any PhotoSuggesting
    ) {
        self.tripRepository = tripRepository
        self.photoRepository = photoRepository
        self.metadataReader = metadataReader
        self.suggester = suggester
    }

    /// 端末に保存する本番の構成。初回はデモのトリップを入れる。
    static func live() throws -> AppDependencies {
        let store = try SwiftDataStore.live()
        try store.seedSampleTripIfEmpty()
        return AppDependencies(
            tripRepository: try SwiftDataTripRepository(store: store),
            photoRepository: SwiftDataPhotoRepository(store: store),
            metadataReader: ImageIOPhotoMetadataReader(),
            suggester: FoundationModelsPhotoSuggester()
        )
    }

    // MARK: - ViewModel

    func makeTripMapViewModel() -> TripMapViewModel {
        TripMapViewModel(
            observeCurrentTrip: ObserveCurrentTripUseCase(tripRepository: tripRepository),
            purgeExpiredPhotos: PurgeExpiredPhotosUseCase(photoRepository: photoRepository),
            removePhoto: RemovePhotoUseCase(photoRepository: photoRepository)
        )
    }

    func makeAddPhotosViewModel(count: Int, trip: Trip, fallbackCenter: Coordinate) -> AddPhotosViewModel {
        AddPhotosViewModel(
            count: count,
            trip: trip,
            fallbackCenter: fallbackCenter,
            readMetadata: ReadPhotoMetadataUseCase(reader: metadataReader),
            suggestText: SuggestPhotoTextUseCase(suggester: suggester),
            addPhotos: AddPhotosUseCase(photoRepository: photoRepository)
        )
    }

    func makeEditPhotoViewModel(photo: Photo) -> EditPhotoViewModel {
        EditPhotoViewModel(photo: photo, updatePhoto: UpdatePhotoUseCase(photoRepository: photoRepository))
    }

    func makePhotoListViewModel(tripID: Trip.ID) -> PhotoListViewModel {
        PhotoListViewModel(
            tripID: tripID,
            observeTrip: ObserveTripUseCase(tripRepository: tripRepository),
            reorderPhotos: ReorderPhotosUseCase(photoRepository: photoRepository),
            removePhoto: RemovePhotoUseCase(photoRepository: photoRepository)
        )
    }

    func makeRecentlyDeletedViewModel(tripID: Trip.ID) -> RecentlyDeletedViewModel {
        RecentlyDeletedViewModel(
            tripID: tripID,
            observeTrip: ObserveTripUseCase(tripRepository: tripRepository),
            restorePhoto: RestorePhotoUseCase(photoRepository: photoRepository),
            deletePhotoPermanently: DeletePhotoPermanentlyUseCase(photoRepository: photoRepository),
            purgeExpiredPhotos: PurgeExpiredPhotosUseCase(photoRepository: photoRepository)
        )
    }
}
