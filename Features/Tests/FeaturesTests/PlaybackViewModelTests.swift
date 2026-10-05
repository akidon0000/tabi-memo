import Domain
import Foundation
@testable import TripMapFeature
import Testing

@MainActor
struct PlaybackViewModelTests {
    private let a = Coordinate(latitude: 0, longitude: 0)
    private let b = Coordinate(latitude: 0, longitude: 0.01)
    private let c = Coordinate(latitude: 0.01, longitude: 0.01)

    @Test func startingNeedsAtLeastTwoPoints() {
        let viewModel = PlaybackViewModel()
        viewModel.start(path: [a], stops: [a])
        #expect(!viewModel.isPlaying)
        #expect(viewModel.sample == nil)
    }

    @Test func startingPlacesTheMarkerAtTheBeginning() {
        let viewModel = PlaybackViewModel()
        viewModel.start(path: [a, b, c], stops: [a, c])
        defer { viewModel.stop() }
        #expect(viewModel.isPlaying)
        #expect(viewModel.sample?.coordinate == a)
    }

    @Test func tickMovesTheMarkerAlongThePathAndPausesAtThePhotos() {
        let viewModel = PlaybackViewModel()
        viewModel.start(path: [a, b, c], stops: [a, b, c])
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
        viewModel.start(path: [a, b], stops: [a, b])
        for _ in 0..<2_000 where viewModel.isPlaying { viewModel.tick(0.1) }
        #expect(!viewModel.isPlaying)
        #expect(viewModel.sample == nil)
    }

    @Test func stoppingClearsTheMarker() {
        let viewModel = PlaybackViewModel()
        viewModel.start(path: [a, b], stops: [])
        viewModel.stop()
        #expect(!viewModel.isPlaying)
        #expect(viewModel.sample == nil)
    }
}
