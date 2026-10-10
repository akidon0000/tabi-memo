import Foundation

/// 画像から作る、タイトル案と解説。
public struct PhotoSuggestion: Hashable, Sendable {
    public var title: String
    public var description: String

    public init(title: String, description: String) {
        self.title = title
        self.description = description
    }
}
