import Domain
import Foundation
@testable import TripMapFeature
import Testing
import TestSupport

@MainActor
struct PlaybackViewModelTests {
    private let a = Coordinate(latitude: 0, longitude: 0)
    private let b = Coordinate(latitude: 0, longitude: 0.01)
    private let c = Coordinate(latitude: 0.01, longitude: 0.01)

    private func photo(_ title: String, minutes: Double, at coordinate: Coordinate) -> Photo {
        Fixtures.photo(title, minutes: minutes, coordinate: coordinate)
    }

    @Test func startingNeedsAtLeastTwoPoints() {
        let viewModel = PlaybackViewModel()
        viewModel.start(path: [a], photos: [photo("a", minutes: 1, at: a)])
        #expect(!viewModel.isPlaying)
        #expect(viewModel.sample == nil)
    }

    @Test func startingPlacesTheMarkerAtTheBeginning() {
        let viewModel = PlaybackViewModel()
        viewModel.start(path: [a, b, c], photos: [photo("a", minutes: 1, at: a), photo("c", minutes: 3, at: c)])
        defer { viewModel.stop() }
        #expect(viewModel.isPlaying)
        #expect(viewModel.sample?.coordinate == a)
    }

    @Test func tickMovesTheMarkerAlongThePathAndPausesAtThePhotos() {
        let viewModel = PlaybackViewModel()
        viewModel.start(path: [a, b, c], photos: [photo("a", minutes: 1, at: a), photo("b", minutes: 2, at: b), photo("c", minutes: 3, at: c)])
        defer { viewModel.stop() }

        // 出発地点の写真で止まる。
        viewModel.tick(0.1)
        #expect(viewModel.sample?.coordinate == a)
        viewModel.tick(PlaybackViewModel.holdSeconds)
        // 止まり終えたら動き出す。
        viewModel.tick(1)
        let moved = viewModel.sample?.coordinate
        #expect((moved?.longitude ?? 0) > 0)

        // 2枚目の写真(b)に着くまで進めると、そこで止まる。
        for _ in 0..<400 { viewModel.tick(0.05) }
        #expect(viewModel.isPlaying)
    }

    @Test func playbackEndsAfterThePathAndTheLastHold() {
        let viewModel = PlaybackViewModel()
        viewModel.start(path: [a, b], photos: [photo("a", minutes: 1, at: a), photo("b", minutes: 2, at: b)])
        for _ in 0..<2_000 where viewModel.isPlaying { viewModel.tick(0.1) }
        #expect(!viewModel.isPlaying)
        #expect(viewModel.sample == nil)
    }

    @Test func stoppingClearsTheMarker() {
        let viewModel = PlaybackViewModel()
        viewModel.start(path: [a, b], photos: [])
        viewModel.stop()
        #expect(!viewModel.isPlaying)
        #expect(viewModel.sample == nil)
    }

    @Test func arrivingAtAPhotoFeaturesItForTwoSecondsThenResumes() {
        let viewModel = PlaybackViewModel()
        let first = photo("a", minutes: 1, at: a)
        let second = photo("b", minutes: 2, at: b)
        viewModel.start(path: [a, b], photos: [first, second])
        defer { viewModel.stop() }

        // 出発地点の写真で止まり、その写真を見せる。
        viewModel.tick(0.1)
        #expect(viewModel.featuredPhotoID == first.id)
        let stoppedAt = viewModel.sample?.coordinate
        viewModel.tick(1.5)
        #expect(viewModel.featuredPhotoID == first.id)
        #expect(viewModel.sample?.coordinate == stoppedAt)

        // 2秒たつと、写真を閉じる。次の更新から動き出す。
        viewModel.tick(0.5)
        #expect(viewModel.featuredPhotoID == nil)
        viewModel.tick(1)
        #expect((viewModel.sample?.coordinate.longitude ?? 0) > 0)

        // 2枚目の写真の場所に着くと、その写真を見せる。
        for _ in 0..<400 where viewModel.featuredPhotoID == nil { viewModel.tick(0.05) }
        #expect(viewModel.featuredPhotoID == second.id)
    }

    @Test func photosAtTheSamePlaceFeatureOnlyTheFirstOne() {
        let viewModel = PlaybackViewModel()
        let first = photo("a", minutes: 1, at: a)
        let same = photo("a2", minutes: 2, at: a)
        viewModel.start(path: [a, b], photos: [first, same])
        defer { viewModel.stop() }
        viewModel.tick(0.1)
        #expect(viewModel.featuredPhotoID == first.id)
    }

    @Test func stoppingClosesTheFeaturedPhoto() {
        let viewModel = PlaybackViewModel()
        viewModel.start(path: [a, b], photos: [photo("a", minutes: 1, at: a)])
        viewModel.tick(0.1)
        viewModel.stop()
        #expect(viewModel.featuredPhotoID == nil)
    }
}
