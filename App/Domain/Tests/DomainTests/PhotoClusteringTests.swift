import Domain
import Foundation
import Testing
import TestSupport

struct PhotoClusteringTests {
    private func photo(_ title: String, minutes: Double, lat: Double, lon: Double) -> Photo {
        Photo(imageData: Data(), coordinate: Coordinate(latitude: lat, longitude: lon), takenAt: Fixtures.date(minutes: minutes), title: title)
    }

    @Test func nearbyPhotosAreGroupedInDateOrder() {
        let photos = [
            photo("late", minutes: 3, lat: 35.0004, lon: 139.0004),
            photo("far", minutes: 2, lat: 36, lon: 140),
            photo("early", minutes: 1, lat: 35, lon: 139),
        ]
        let clusters = PhotoClustering.clusters(of: photos, latitudeThreshold: 0.001, longitudeThreshold: 0.001)
        #expect(clusters.map { $0.photos.map(\.title) } == [["early", "late"], ["far"]])
        #expect(clusters[0].coordinate == Coordinate(latitude: 35, longitude: 139))
    }

    @Test func zeroThresholdKeepsEveryPhotoSeparate() {
        let photos = [photo("a", minutes: 1, lat: 35, lon: 139), photo("b", minutes: 2, lat: 35, lon: 139)]
        #expect(PhotoClustering.clusters(of: photos, latitudeThreshold: 0, longitudeThreshold: 0).count == 2)
    }
}
