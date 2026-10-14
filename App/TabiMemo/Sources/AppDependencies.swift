import AddPhotosFeature
import CameraFeature
import DataLayer
import Domain
import EditPhotoFeature
import PhotoListFeature
import RecentlyDeletedFeature
import TripListFeature
import TripMapFeature

/// 依存の組み立て(Composition Root)。Repository と Service をここで作り、UseCase を通して各画面の ViewModel に渡す。
/// 地図画面が開く子画面の作り方は `tripMapChildren` にまとめて渡す(各画面は他の画面や、この型を知らない)。
@MainActor
final class AppDependencies {
    private let tripRepository: any TripRepository
    private let photoRepository: any PhotoRepository
    private let metadataReader: any PhotoMetadataReading
    private let suggester: any PhotoSuggesting
    private let routeFinder: any RouteFinding
    private let routeEditRepository: any RouteEditRepository
    private let locationProvider: any LocationProviding
    private let photoLibrary: any PhotoLibrarySaving

    init(
        tripRepository: any TripRepository,
        photoRepository: any PhotoRepository,
        metadataReader: any PhotoMetadataReading,
        suggester: any PhotoSuggesting,
        routeFinder: any RouteFinding,
        routeEditRepository: any RouteEditRepository,
        locationProvider: any LocationProviding,
        photoLibrary: any PhotoLibrarySaving
    ) {
        self.tripRepository = tripRepository
        self.photoRepository = photoRepository
        self.metadataReader = metadataReader
        self.suggester = suggester
        self.routeFinder = routeFinder
        self.routeEditRepository = routeEditRepository
        self.locationProvider = locationProvider
        self.photoLibrary = photoLibrary
    }

    /// 端末に保存する本番の構成。
    static func live() throws -> AppDependencies {
        let store = try SwiftDataStore.live()
        return AppDependencies(
            tripRepository: try SwiftDataTripRepository(store: store),
            photoRepository: SwiftDataPhotoRepository(store: store),
            metadataReader: ImageIOPhotoMetadataReader(),
            suggester: FoundationModelsPhotoSuggester(),
            routeFinder: MapKitRouteFinder(),
            routeEditRepository: SwiftDataRouteEditRepository(store: store),
            locationProvider: CoreLocationProvider(),
            photoLibrary: PhotosPhotoLibrary()
        )
    }

    /// アプリの最初の画面(トリップの一覧)。地図画面などの子画面の ViewModel もここから作られる。
    func makeTripListView() -> TripListView {
        TripListView(viewModel: makeTripListViewModel()) { [self] tripID in
            TripMapView(viewModel: makeTripMapViewModel(tripID: tripID), children: tripMapChildren)
        }
    }

    // MARK: - ViewModel

    private var tripMapChildren: TripMapChildren {
        TripMapChildren(
            makeEditPhoto: { [self] in makeEditPhotoViewModel(photo: $0) },
            makePhotoList: { [self] in makePhotoListViewModel(tripID: $0) },
            makeRecentlyDeleted: { [self] in makeRecentlyDeletedViewModel(tripID: $0) },
            makeCamera: { [self] in makeCameraViewModel() },
            makeAddPhotos: { [self] in makeAddPhotosViewModel(count: $0, trip: $1, fallbackCenter: $2, placement: $3) }
        )
    }

    private func makeTripListViewModel() -> TripListViewModel {
        TripListViewModel(
            observeTrips: ObserveTripsUseCase(tripRepository: tripRepository),
            createTrip: CreateTripUseCase(tripRepository: tripRepository),
            renameTrip: RenameTripUseCase(tripRepository: tripRepository),
            removeTrip: RemoveTripUseCase(tripRepository: tripRepository),
            restoreTrip: RestoreTripUseCase(tripRepository: tripRepository),
            deleteTripPermanently: DeleteTripPermanentlyUseCase(tripRepository: tripRepository),
            purgeExpiredTrips: PurgeExpiredTripsUseCase(tripRepository: tripRepository)
        )
    }

    private func makeCameraViewModel() -> CameraViewModel {
        CameraViewModel(
            getLocation: GetCurrentLocationUseCase(provider: locationProvider),
            saveToLibrary: SavePhotoToLibraryUseCase(library: photoLibrary)
        )
    }

    private func makeTripMapViewModel(tripID: Trip.ID) -> TripMapViewModel {
        TripMapViewModel(
            tripID: tripID,
            observeTrip: ObserveTripUseCase(tripRepository: tripRepository),
            getLocation: GetCurrentLocationUseCase(provider: locationProvider),
            purgeExpiredPhotos: PurgeExpiredPhotosUseCase(photoRepository: photoRepository),
            removePhoto: RemovePhotoUseCase(photoRepository: photoRepository),
            route: RouteViewModel(
                findRoute: FindRouteUseCase(finder: routeFinder),
                setWaypoints: SetRouteWaypointsUseCase(routeEditRepository: routeEditRepository)
            )
        )
    }

    private func makeAddPhotosViewModel(count: Int, trip: Trip, fallbackCenter: Coordinate, placement: Coordinate?) -> AddPhotosViewModel {
        AddPhotosViewModel(
            count: count,
            trip: trip,
            fallbackCenter: fallbackCenter,
            placement: placement,
            readMetadata: ReadPhotoMetadataUseCase(reader: metadataReader),
            suggestText: SuggestPhotoTextUseCase(suggester: suggester),
            addPhotos: AddPhotosUseCase(photoRepository: photoRepository)
        )
    }

    private func makeEditPhotoViewModel(photo: Photo) -> EditPhotoViewModel {
        EditPhotoViewModel(photo: photo, updatePhoto: UpdatePhotoUseCase(photoRepository: photoRepository))
    }

    private func makePhotoListViewModel(tripID: Trip.ID) -> PhotoListViewModel {
        PhotoListViewModel(
            tripID: tripID,
            observeTrip: ObserveTripUseCase(tripRepository: tripRepository),
            reorderPhotos: ReorderPhotosUseCase(photoRepository: photoRepository),
            removePhoto: RemovePhotoUseCase(photoRepository: photoRepository)
        )
    }

    private func makeRecentlyDeletedViewModel(tripID: Trip.ID) -> RecentlyDeletedViewModel {
        RecentlyDeletedViewModel(
            tripID: tripID,
            observeTrip: ObserveTripUseCase(tripRepository: tripRepository),
            restorePhoto: RestorePhotoUseCase(photoRepository: photoRepository),
            deletePhotoPermanently: DeletePhotoPermanentlyUseCase(photoRepository: photoRepository),
            purgeExpiredPhotos: PurgeExpiredPhotosUseCase(photoRepository: photoRepository)
        )
    }
}
