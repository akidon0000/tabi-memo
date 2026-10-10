import Domain
import SwiftUI
import UIKit

// 写真の画像データを、画面で使う形にする。

extension Photo {
    /// 毎回同じ UIImage から作る。描画のたびに作り直すと、SwiftUI が「中身が変わった」とみなしてアニメーション中にクロスフェードし、
    /// 写真が薄く見える(左右スワイプの途中など)。JPEG の展開も毎回走らずに済む。
    public var image: Image {
        PhotoImageCache.uiImage(for: self).map(Image.init(uiImage:)) ?? Image(systemName: "photo")
    }

    /// 幅 / 高さ。画像が読めないときは横長(3:2)として扱う。
    public var aspectRatio: CGFloat {
        guard let size = PhotoImageCache.uiImage(for: self)?.size, size.height > 0 else { return 1.5 }
        return size.width / size.height
    }
}

/// 展開済みの写真の画像。写真の ID ごとに1つ持つ(写真の画像は、保存した後に差し替わらない)。
public enum PhotoImageCache {
    private static let cache = NSCache<NSUUID, UIImage>()

    public static func uiImage(for photo: Photo) -> UIImage? {
        let key = photo.id as NSUUID
        if let cached = cache.object(forKey: key) { return cached }
        guard let image = UIImage(data: photo.imageData) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }
}

extension Image {
    /// 画像データから作る。読めなければ写真の記号を出す。保存前の写真(追加の流れ)で使う。
    public init(imageData: Data) {
        if let uiImage = UIImage(data: imageData) {
            self.init(uiImage: uiImage)
        } else {
            self.init(systemName: "photo")
        }
    }
}
