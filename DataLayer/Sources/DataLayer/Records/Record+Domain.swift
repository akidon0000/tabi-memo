import Domain
import Foundation

// 保存の形(Record)と Domain の型の変換は、このファイルだけに書く。

extension TripRecord {
    func toDomain() -> Trip {
        Trip(
            id: id,
            name: name,
            startedAt: startedAt,
            endedAt: endedAt,
            locationPoints: locationPoints.map { $0.toDomain() },
            photos: photos.map { $0.toDomain() }
        )
    }
}

extension PhotoRecord {
    convenience init(_ photo: NewPhoto) {
        self.init(
            id: photo.id,
            imageData: photo.imageData,
            latitude: photo.coordinate.latitude,
            longitude: photo.coordinate.longitude,
            takenAt: photo.takenAt,
            isLocationManuallyPlaced: photo.isLocationManuallyPlaced,
            title: photo.title,
            memo: photo.memo
        )
    }

    func toDomain() -> Photo {
        Photo(
            id: id,
            imageData: imageData,
            coordinate: Coordinate(latitude: latitude, longitude: longitude),
            takenAt: takenAt,
            isLocationManuallyPlaced: isLocationManuallyPlaced,
            title: title,
            memo: memo,
            removedAt: removedAt
        )
    }

    func apply(_ edit: PhotoEdit) {
        takenAt = edit.takenAt
        latitude = edit.coordinate.latitude
        longitude = edit.coordinate.longitude
        isLocationManuallyPlaced = edit.isLocationManuallyPlaced
        title = edit.title
        memo = edit.memo
    }
}

extension LocationPointRecord {
    func toDomain() -> LocationPoint {
        LocationPoint(
            id: id,
            coordinate: Coordinate(latitude: latitude, longitude: longitude),
            altitude: altitude,
            timestamp: timestamp
        )
    }
}
