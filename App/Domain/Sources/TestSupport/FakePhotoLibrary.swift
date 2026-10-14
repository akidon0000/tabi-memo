import Domain
import Foundation

/// テスト用の PhotoLibrarySaving。保存された画像データを記録する。
@MainActor
public final class FakePhotoLibrary: PhotoLibrarySaving {
    public private(set) var saved: [Data] = []

    public init() {}

    public func save(imageData: Data) async throws {
        saved.append(imageData)
    }
}
