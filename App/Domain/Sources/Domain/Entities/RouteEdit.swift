import Foundation

/// 写真と写真の間の線を、ユーザーが直した内容。通ってほしい点(経由点)を、通る順に持つ。
/// 写真の ID の組で持つので、写真の位置を動かしても、直した内容は残る。
public struct RouteEdit: Hashable, Sendable {
    public var fromPhotoID: Photo.ID
    public var toPhotoID: Photo.ID
    public var waypoints: [Coordinate]

    public init(fromPhotoID: Photo.ID, toPhotoID: Photo.ID, waypoints: [Coordinate]) {
        self.fromPhotoID = fromPhotoID
        self.toPhotoID = toPhotoID
        self.waypoints = waypoints
    }
}
