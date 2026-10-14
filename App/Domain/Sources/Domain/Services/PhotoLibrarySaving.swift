import Foundation

/// 撮った写真を、端末の写真ライブラリに保存する。
@MainActor
public protocol PhotoLibrarySaving {
    func save(imageData: Data) async throws
}
