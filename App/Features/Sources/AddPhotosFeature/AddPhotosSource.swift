import Domain
import PhotosUI
import SwiftUI

/// 追加フォームに渡す写真の出どころ。ライブラリで選んだ項目か、アプリ内カメラで撮った写真。
public enum AddPhotosSource {
    case library([PhotosPickerItem])
    case captured([CapturedPhoto])

    public var count: Int {
        switch self {
        case .library(let items): items.count
        case .captured(let photos): photos.count
        }
    }
}
