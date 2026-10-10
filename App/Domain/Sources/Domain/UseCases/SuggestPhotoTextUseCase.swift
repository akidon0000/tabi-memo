import Foundation

/// 画像から、タイトル案と解説を作る。作れなければ nil(提案欄を出さない)。
@MainActor
public struct SuggestPhotoTextUseCase {
    private let suggester: any PhotoSuggesting

    public init(suggester: any PhotoSuggesting) {
        self.suggester = suggester
    }

    public func execute(imageData: Data) async -> PhotoSuggestion? {
        await suggester.suggest(from: imageData)
    }
}
