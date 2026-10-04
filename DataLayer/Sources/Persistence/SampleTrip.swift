import Foundation
import UIKit

/// 初回起動で入れるデモ: 渋谷駅から代々木公園までの散歩。なめらかな軌跡と、写真のピン3枚。
enum SampleTrip {
    private struct PhotoSpec {
        var waypointIndex: Int
        var offsetMinutes: Double
        var color: UIColor
        var label: String
        var size: CGSize
        var memo: String
    }

    private static let waypoints: [(lat: Double, lon: Double)] = [
        (35.6580, 139.7016),  // 渋谷駅
        (35.6620, 139.7010),
        (35.6650, 139.7020),
        (35.6690, 139.6980),
        (35.6710, 139.6950),  // 代々木公園入口
        (35.6725, 139.6935),
        (35.6730, 139.6930),  // 公園内
    ]

    private static let photoSpecs: [PhotoSpec] = [
        // 縦どりの写真。
        PhotoSpec(
            waypointIndex: 0, offsetMinutes: 0, color: .systemBlue, label: "渋谷駅", size: CGSize(width: 600, height: 800),
            memo: "ハチ公前は待ち合わせの人でいっぱい。ここから代々木公園まで歩いて向かう。\n\n天気は快晴。スクランブル交差点を渡って、井ノ頭通りへ。"
        ),
        PhotoSpec(
            waypointIndex: 3, offsetMinutes: 20, color: .systemGreen, label: "代々木公園入口", size: CGSize(width: 800, height: 600),
            memo: "公園の入口に到着。\n\n・木陰が気持ちいい\n・売店でコーヒーを買った\n・犬の散歩をしている人が多い\n\n"
                + "奥の広場まで行ってみる。ベンチで少し休む予定。長めのメモで、スクロールしたときに写真ごと上に流れていくかを確認するための文章です。"
        ),
        PhotoSpec(
            waypointIndex: 6, offsetMinutes: 40, color: .systemOrange, label: "公園のベンチ", size: CGSize(width: 600, height: 600),
            memo: "公園のベンチで休憩。"
        ),
    ]

    /// 呼ぶたびに新しいインスタンスを作る。
    static func make() -> TripRecord {
        let start = Calendar.current.date(byAdding: .hour, value: -3, to: .now) ?? .now
        let trip = TripRecord(name: "渋谷から代々木公園散歩", startedAt: start, endedAt: start.addingTimeInterval(45 * 60))
        for point in routePoints(start: start) { point.trip = trip }
        for photo in photos(start: start) { photo.trip = trip }
        return trip
    }

    /// 経由地のあいだを直線で補間した、30点の軌跡。
    private static func routePoints(start: Date) -> [LocationPointRecord] {
        let pointCount = 30
        return (0..<pointCount).map { i in
            let progress = Double(i) / Double(pointCount - 1)
            let segment = progress * Double(waypoints.count - 1)
            let index = min(Int(segment), waypoints.count - 2)
            let localProgress = segment - Double(index)
            let a = waypoints[index]
            let b = waypoints[index + 1]
            return LocationPointRecord(
                latitude: a.lat + (b.lat - a.lat) * localProgress,
                longitude: a.lon + (b.lon - a.lon) * localProgress,
                timestamp: start.addingTimeInterval(Double(i) * 90)
            )
        }
    }

    private static func photos(start: Date) -> [PhotoRecord] {
        photoSpecs.map { spec in
            let waypoint = waypoints[spec.waypointIndex]
            return PhotoRecord(
                id: UUID(),
                imageData: placeholderImage(color: spec.color, label: spec.label, size: spec.size),
                latitude: waypoint.lat,
                longitude: waypoint.lon,
                takenAt: start.addingTimeInterval(spec.offsetMinutes * 60),
                isLocationManuallyPlaced: false,
                title: "",
                memo: spec.memo
            )
        }
    }

    /// 単色の仮の写真。デモが画像ファイルに依存しないようにする。
    private static func placeholderImage(color: UIColor, label: String, size: CGSize) -> Data {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            color.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 44),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraph,
            ]
            let textRect = CGRect(x: 20, y: size.height / 2 - 30, width: size.width - 40, height: 60)
            (label as NSString).draw(in: textRect, withAttributes: attributes)
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }
}
