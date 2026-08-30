import Foundation
import SwiftData
import UIKit

enum SampleData {
    /// Seeds a demo trip on first launch so the app isn't empty.
    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Trip>())) ?? 0
        guard existing == 0 else { return }

        context.insert(makeTrip())
        try? context.save()
    }

    /// Builds a fresh demo trip (new instances each call): a walk from Shibuya Station
    /// to Yoyogi Park, with a smoothly interpolated route and a few photo pins.
    static func makeTrip() -> Trip {
        let start = Calendar.current.date(byAdding: .hour, value: -3, to: .now) ?? .now
        let trip = Trip(name: "渋谷から代々木公園散歩", startedAt: start)
        trip.endedAt = start.addingTimeInterval(45 * 60)

        let waypoints: [(lat: Double, lon: Double)] = [
            (35.6580, 139.7016),  // 渋谷駅
            (35.6620, 139.7010),
            (35.6650, 139.7020),
            (35.6690, 139.6980),
            (35.6710, 139.6950),  // 代々木公園入口
            (35.6725, 139.6935),
            (35.6730, 139.6930),  // 公園内
        ]

        let pointCount = 30
        for i in 0..<pointCount {
            let progress = Double(i) / Double(pointCount - 1)
            let segment = progress * Double(waypoints.count - 1)
            let index = min(Int(segment), waypoints.count - 2)
            let localProgress = segment - Double(index)
            let a = waypoints[index]
            let b = waypoints[index + 1]
            let point = LocationPoint(
                latitude: a.lat + (b.lat - a.lat) * localProgress,
                longitude: a.lon + (b.lon - a.lon) * localProgress,
                timestamp: start.addingTimeInterval(Double(i) * 90)
            )
            point.trip = trip
        }

        let photoSpecs: [(waypointIndex: Int, offsetMinutes: Double, color: UIColor, label: String)] = [
            (0, 0, .systemBlue, "渋谷駅"),
            (3, 20, .systemGreen, "代々木公園入口"),
            (6, 40, .systemOrange, "公園のベンチ"),
        ]
        for spec in photoSpecs {
            let waypoint = waypoints[spec.waypointIndex]
            let photo = TripPhoto(
                imageData: placeholderImage(color: spec.color, label: spec.label),
                latitude: waypoint.lat,
                longitude: waypoint.lon,
                takenAt: start.addingTimeInterval(spec.offsetMinutes * 60)
            )
            photo.trip = trip
        }

        return trip
    }

    /// Solid-color placeholder photo so the demo doesn't depend on bundled image assets.
    private static func placeholderImage(color: UIColor, label: String) -> Data {
        let size = CGSize(width: 600, height: 600)
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
