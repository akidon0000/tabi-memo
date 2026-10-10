import Foundation
import Testing
@testable import Domain

struct PathPlaybackTests {
    /// 東へ約 1.1km(経度 0.01 度、赤道付近)→ 北へ約 1.1km。
    private let a = Coordinate(latitude: 0, longitude: 0)
    private let b = Coordinate(latitude: 0, longitude: 0.01)
    private let c = Coordinate(latitude: 0.01, longitude: 0.01)

    @Test func lengthIsTheSumOfTheSegments() {
        let playback = PathPlayback(path: [a, b, c])
        #expect(abs(playback.length - 2_224) < 10)
    }

    @Test func sampleAtZeroAndAtTheEndAreTheEndpoints() {
        let playback = PathPlayback(path: [a, b, c])
        #expect(playback.sample(atDistance: 0)?.coordinate == a)
        #expect(playback.sample(atDistance: playback.length)?.coordinate == c)
        #expect(playback.sample(atDistance: 99_999)?.coordinate == c)
        #expect(playback.sample(atDistance: -5)?.coordinate == a)
    }

    @Test func sampleInTheMiddleOfASegmentIsInterpolatedWithItsHeading() throws {
        let playback = PathPlayback(path: [a, b, c])
        let east = try #require(playback.sample(atDistance: playback.length / 4))
        #expect(abs(east.coordinate.longitude - 0.005) < 0.0002)
        #expect(abs(east.heading - 90) < 0.5)

        let north = try #require(playback.sample(atDistance: playback.length * 3 / 4))
        #expect(abs(north.coordinate.latitude - 0.005) < 0.0002)
        #expect(abs(north.heading) < 0.5)
    }

    @Test func emptyAndSinglePointPaths() {
        #expect(PathPlayback(path: []).sample(atDistance: 0) == nil)
        #expect(PathPlayback(path: [a]).sample(atDistance: 10)?.coordinate == a)
        #expect(PathPlayback(path: [a]).length == 0)
    }

    @Test func stopsAreFoundInTheOrderTheyAreVisited() {
        let playback = PathPlayback(path: [a, b, c])
        let distances = playback.distances(near: [a, b, c])
        #expect(distances.count == 3)
        #expect(distances[0] == 0)
        #expect(distances == distances.sorted())
        #expect(abs(distances[2] - playback.length) < 1)
    }

    @Test func stopsAtTheSamePlaceShareADistance() {
        let playback = PathPlayback(path: [a, b, c])
        let distances = playback.distances(near: [b, b])
        #expect(distances[0] == distances[1])
    }
}
