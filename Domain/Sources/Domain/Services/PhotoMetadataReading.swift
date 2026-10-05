import Foundation

/// 画像データから、撮影日時と位置を読む。
@MainActor
public protocol PhotoMetadataReading {
    func read(from imageData: Data) -> PhotoMetadata
}
