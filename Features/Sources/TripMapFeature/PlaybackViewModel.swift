import Domain
import Foundation
import Observation

/// 線に沿った再生の状態。経路に沿って目印を動かし、写真の場所では少し止まる。
@MainActor
@Observable
public final class PlaybackViewModel {
    /// 写真の場所で止まる秒数。
    static let holdSeconds: TimeInterval = 1.2
    /// 動いている間に、全長を進み切るまでのおおよその秒数(止まる時間は含まない)。
    static let travelSeconds: TimeInterval = 20
    /// 短い経路でも、これより遅くは進まない(m/秒)。
    static let minimumSpeed = 30.0

    private(set) var isPlaying = false
    /// いまの目印の位置と向き。再生中だけ値がある。
    private(set) var sample: PathPlayback.Sample?

    private var playback: PathPlayback?
    private var stops: [Double] = []
    private var nextStop = 0
    private var distance = 0.0
    private var speed = PlaybackViewModel.minimumSpeed
    private var holdRemaining = 0.0
    private var ticker: Task<Void, Never>?

    public init() {}

    /// 再生を始める。`path` は地図に引いている線、`stops` は写真の場所(撮影順)。線が2点に満たなければ何もしない。
    func start(path: [Coordinate], stops photoCoordinates: [Coordinate]) {
        guard path.count > 1 else { return }
        stop()
        let playback = PathPlayback(path: path)
        self.playback = playback
        speed = max(playback.length / Self.travelSeconds, Self.minimumSpeed)
        // 同じ場所の写真は、1回だけ止まる。
        stops = playback.distances(near: photoCoordinates).reduce(into: []) { result, distance in
            if result.last.map({ distance - $0 > 1 }) ?? true { result.append(distance) }
        }
        nextStop = 0
        distance = 0
        holdRemaining = 0
        sample = playback.sample(atDistance: 0)
        isPlaying = true
        runTicker()
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
        isPlaying = false
        sample = nil
        playback = nil
    }

    /// `dt` 秒ぶん進める。止まっている間は止まり、最後まで来て止まり終えたら、再生を終える。
    func tick(_ dt: TimeInterval) {
        guard isPlaying, let playback else { return }
        if holdRemaining > 0 {
            holdRemaining -= dt
            return
        }
        if distance >= playback.length {
            stop()
            return
        }
        distance = min(distance + speed * dt, playback.length)
        if nextStop < stops.count, distance >= stops[nextStop] {
            distance = stops[nextStop]
            nextStop += 1
            holdRemaining = Self.holdSeconds
        }
        sample = playback.sample(atDistance: distance)
    }

    private func runTicker() {
        ticker = Task {
            let clock = ContinuousClock()
            var last = clock.now
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(33))
                let now = clock.now
                let elapsed = last.duration(to: now)
                last = now
                tick(Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18)
            }
        }
    }
}
