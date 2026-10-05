import Foundation

/// トリップの軌跡の1点。
public struct LocationPoint: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var coordinate: Coordinate
    public var altitude: Double?
    public var timestamp: Date

    public init(id: UUID = UUID(), coordinate: Coordinate, altitude: Double? = nil, timestamp: Date) {
        self.id = id
        self.coordinate = coordinate
        self.altitude = altitude
        self.timestamp = timestamp
    }
}
