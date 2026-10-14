import Foundation

/// 撮った写真を、端末の写真ライブラリにも保存する。失敗しても、アプリ内への保存は止めない。
@MainActor
public struct SavePhotoToLibraryUseCase {
    private let library: any PhotoLibrarySaving

    public init(library: any PhotoLibrarySaving) {
        self.library = library
    }

    public func execute(imageData: Data) async {
        try? await library.save(imageData: imageData)
    }
}
