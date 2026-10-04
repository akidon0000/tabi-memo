import Foundation

/// 選んだ画像から、撮影日時と位置を読む。
@MainActor
public struct ReadPhotoMetadataUseCase {
    private let reader: any PhotoMetadataReading

    public init(reader: any PhotoMetadataReading) {
        self.reader = reader
    }

    public func execute(imageData: Data) -> PhotoMetadata {
        reader.read(from: imageData)
    }
}
