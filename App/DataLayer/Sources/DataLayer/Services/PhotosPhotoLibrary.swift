import Domain
import Foundation
import Photos

/// 撮った写真を、「追加のみ」の許可で、端末の写真ライブラリに保存する。
public struct PhotosPhotoLibrary: PhotoLibrarySaving {
    public init() {}

    public func save(imageData: Data) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { return }
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: imageData, options: nil)
        }
    }
}
