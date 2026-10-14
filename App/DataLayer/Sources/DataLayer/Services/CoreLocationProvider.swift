import CoreLocation
import Domain
import Foundation

/// 端末の現在地を、位置情報(使用中のみ)の許可のもとで1回だけ求める。許可が無い・数秒で求まらないときは nil。
public struct CoreLocationProvider: LocationProviding {
    private let timeoutSeconds: Double

    public init(timeoutSeconds: Double = 5) {
        self.timeoutSeconds = timeoutSeconds
    }

    public func currentLocation() async -> Coordinate? {
        let session = CLServiceSession(authorization: .whenInUse)
        defer { session.invalidate() }
        return await withTaskGroup(of: Coordinate?.self) { group in
            group.addTask { await Self.firstLocation() }
            group.addTask {
                try? await Task.sleep(for: .seconds(timeoutSeconds))
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }

    private static func firstLocation() async -> Coordinate? {
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                if let location = update.location {
                    return Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                }
                if update.authorizationDenied || update.authorizationDeniedGlobally { return nil }
            }
        } catch {
            return nil
        }
        return nil
    }
}
