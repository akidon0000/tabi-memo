import CoreLocation
import Foundation

/// 軌跡上の1点。移動フェーズでこの点に到達し、写真があればその後の停留フェーズで留まる。
struct ReplayKeyframe {
    let coordinate: CLLocationCoordinate2D
    /// この点に向かう進行方向(度、北=0、東=90)。
    let heading: Double
    /// リプレイ開始からこの点に到達する(=移動フェーズが終わる)までの秒数。
    let arrivalTime: TimeInterval
    /// 直前のキーフレームからこの点まで移動するのにかける秒数。
    let moveDuration: TimeInterval
    /// 到達後、この点に留まる秒数(写真がなければ0)。
    let holdDuration: TimeInterval
    let photo: TripPhoto?

    /// 出発時刻(=留まり終えてリプレイ上で次へ動き出す時刻)。
    var departureTime: TimeInterval { arrivalTime + holdDuration }
}

enum ReplayTimeline {
    private static let minSegmentDuration: TimeInterval = 0.35
    private static let maxSegmentDuration: TimeInterval = 4.0
    /// 密度ベースの基準巡航速度(m/秒)。区間距離をこれで割った値がベースの移動尺になる。
    private static let densityBaseSpeed: Double = 55
    /// 写真が近くにある区間を密度ベースでどれだけゆっくりにするか(移動尺の倍率)。
    private static let densitySlowdownFactor: Double = 2.2
    /// 実経過時間から尺を出す際の圧縮係数(sqrt(秒) * この値)。
    private static let timeCompressionFactor: Double = 0.32

    static func build(
        trip: Trip,
        pacing: ReplayPacingStyle,
        photoStyle: ReplayPhotoDisplayStyle
    ) -> [ReplayKeyframe] {
        let points = trip.locationPoints.sorted { $0.timestamp < $1.timestamp }
        guard points.count >= 2 else { return [] }

        var remainingPhotos = trip.photos.sorted { $0.takenAt < $1.takenAt }
        func popPhoto(before cutoff: Date) -> TripPhoto? {
            guard let first = remainingPhotos.first, first.takenAt <= cutoff else { return nil }
            return remainingPhotos.removeFirst()
        }

        var keyframes: [ReplayKeyframe] = []
        let initialHeading = heading(from: points[0].coordinate, to: points[1].coordinate)
        let firstPhoto = popPhoto(before: points[0].timestamp)
        keyframes.append(
            ReplayKeyframe(
                coordinate: points[0].coordinate,
                heading: initialHeading,
                arrivalTime: 0,
                moveDuration: 0,
                holdDuration: firstPhoto != nil ? photoStyle.holdDuration : 0,
                photo: firstPhoto
            ))

        for i in 0..<(points.count - 1) {
            let a = points[i]
            let b = points[i + 1]
            let travelHeading = heading(from: a.coordinate, to: b.coordinate)
            let distance = a.location.distance(from: b.location)
            let realElapsed = b.timestamp.timeIntervalSince(a.timestamp)

            var moveDuration = segmentDuration(pacing: pacing, distance: distance, realElapsed: realElapsed)
            let photo = popPhoto(before: b.timestamp)
            var holdDuration: TimeInterval = 0
            if photo != nil {
                holdDuration = photoStyle.holdDuration
                if pacing == .densityBased {
                    moveDuration *= densitySlowdownFactor
                }
            }

            let previous = keyframes[keyframes.count - 1]
            keyframes.append(
                ReplayKeyframe(
                    coordinate: b.coordinate,
                    heading: travelHeading,
                    arrivalTime: previous.departureTime + moveDuration,
                    moveDuration: moveDuration,
                    holdDuration: holdDuration,
                    photo: photo
                ))
        }

        // 経路の時間範囲外に撮られた写真(取りこぼし)は最後の点で追加の停留として見せる。
        if !remainingPhotos.isEmpty, let last = keyframes.last {
            var previous = last
            for leftover in remainingPhotos {
                let keyframe = ReplayKeyframe(
                    coordinate: previous.coordinate,
                    heading: previous.heading,
                    arrivalTime: previous.departureTime,
                    moveDuration: 0,
                    holdDuration: photoStyle.holdDuration,
                    photo: leftover
                )
                keyframes.append(keyframe)
                previous = keyframe
            }
        }

        return keyframes
    }

    private static func segmentDuration(pacing: ReplayPacingStyle, distance: Double, realElapsed: TimeInterval) -> TimeInterval {
        let raw: Double =
            switch pacing {
            case .timeBased:
                sqrt(max(realElapsed, 0)) * timeCompressionFactor
            case .densityBased:
                distance / densityBaseSpeed
            }
        return min(max(raw, minSegmentDuration), maxSegmentDuration)
    }

    private static func heading(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        let radians = atan2(y, x)
        let degrees = radians * 180 / .pi
        return degrees < 0 ? degrees + 360 : degrees
    }
}

extension LocationPoint {
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}
