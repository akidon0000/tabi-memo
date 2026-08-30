import CoreLocation
import Foundation

/// ある経過時間におけるリプレイの状態(位置・向き・表示中の写真)。
struct ReplaySample {
    let coordinate: CLLocationCoordinate2D
    let heading: Double
    /// 現在停留中で表示すべき写真。移動中はnil。
    let photo: TripPhoto?
    let isFinished: Bool
}

/// [ReplayKeyframe] と経過時間から、今この瞬間のカメラ位置・写真表示状態を補間して求める。
enum ReplayPlayhead {
    static func totalDuration(_ keyframes: [ReplayKeyframe]) -> TimeInterval {
        keyframes.last?.departureTime ?? 0
    }

    static func sample(keyframes: [ReplayKeyframe], elapsed: TimeInterval) -> ReplaySample {
        guard let first = keyframes.first, let last = keyframes.last else {
            return ReplaySample(coordinate: .init(latitude: 0, longitude: 0), heading: 0, photo: nil, isFinished: true)
        }

        if elapsed >= last.departureTime {
            return ReplaySample(coordinate: last.coordinate, heading: last.heading, photo: nil, isFinished: true)
        }

        // 最初のキーフレームでの停留(写真がある場合はここで表示)。
        if elapsed <= first.departureTime {
            return ReplaySample(coordinate: first.coordinate, heading: first.heading, photo: first.photo, isFinished: false)
        }

        for i in 0..<(keyframes.count - 1) {
            let previous = keyframes[i]
            let target = keyframes[i + 1]
            guard elapsed <= target.departureTime else { continue }

            if elapsed <= target.arrivalTime {
                let segmentStart = previous.departureTime
                let fraction = target.moveDuration > 0 ? (elapsed - segmentStart) / target.moveDuration : 1
                let clamped = min(max(fraction, 0), 1)
                return ReplaySample(
                    coordinate: lerpCoordinate(previous.coordinate, target.coordinate, clamped),
                    heading: lerpHeading(previous.heading, target.heading, clamped),
                    photo: nil,
                    isFinished: false
                )
            } else {
                return ReplaySample(coordinate: target.coordinate, heading: target.heading, photo: target.photo, isFinished: false)
            }
        }

        return ReplaySample(coordinate: last.coordinate, heading: last.heading, photo: nil, isFinished: true)
    }

    private static func lerpCoordinate(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D, _ t: Double) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: a.latitude + (b.latitude - a.latitude) * t,
            longitude: a.longitude + (b.longitude - a.longitude) * t
        )
    }

    /// 最短経路(±180度以内)で角度を補間する。
    private static func lerpHeading(_ a: Double, _ b: Double, _ t: Double) -> Double {
        var diff = (b - a).truncatingRemainder(dividingBy: 360)
        if diff > 180 { diff -= 360 }
        if diff < -180 { diff += 360 }
        let result = (a + diff * t).truncatingRemainder(dividingBy: 360)
        return result < 0 ? result + 360 : result
    }
}
