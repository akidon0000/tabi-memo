import Foundation

/// 画像から、タイトル案と解説を作る。作れないとき(モデルが使えないなど)は nil。
@MainActor
public protocol PhotoSuggesting {
    func suggest(from imageData: Data) async -> PhotoSuggestion?
}
