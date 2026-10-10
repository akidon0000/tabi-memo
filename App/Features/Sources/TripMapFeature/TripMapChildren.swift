import AddPhotosFeature
import Domain
import EditPhotoFeature
import PhotoListFeature
import RecentlyDeletedFeature

/// 地図画面が開く子画面の ViewModel の作り方。作る側(App の AppDependencies)から渡す。
public struct TripMapChildren {
    let makeEditPhoto: (Photo) -> EditPhotoViewModel
    let makePhotoList: (Trip.ID) -> PhotoListViewModel
    let makeRecentlyDeleted: (Trip.ID) -> RecentlyDeletedViewModel
    /// `placement` は、地図の長押しで指定された位置。あれば、選んだ写真すべてをそこに置く。
    let makeAddPhotos: (_ count: Int, _ trip: Trip, _ fallbackCenter: Coordinate, _ placement: Coordinate?) -> AddPhotosViewModel

    public init(
        makeEditPhoto: @escaping (Photo) -> EditPhotoViewModel,
        makePhotoList: @escaping (Trip.ID) -> PhotoListViewModel,
        makeRecentlyDeleted: @escaping (Trip.ID) -> RecentlyDeletedViewModel,
        makeAddPhotos: @escaping (_ count: Int, _ trip: Trip, _ fallbackCenter: Coordinate, _ placement: Coordinate?) -> AddPhotosViewModel
    ) {
        self.makeEditPhoto = makeEditPhoto
        self.makePhotoList = makePhotoList
        self.makeRecentlyDeleted = makeRecentlyDeleted
        self.makeAddPhotos = makeAddPhotos
    }
}
