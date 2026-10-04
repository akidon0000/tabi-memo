import Domain
import SwiftUI
import UIKit

// 写真の画像データを、画面で使う形にする。

extension Photo {
    var image: Image { Image(imageData: imageData) }

    /// 幅 / 高さ。画像が読めないときは横長(3:2)として扱う。
    var aspectRatio: CGFloat {
        guard let size = UIImage(data: imageData)?.size, size.height > 0 else { return 1.5 }
        return size.width / size.height
    }
}

extension Image {
    /// 画像データから作る。読めなければ写真の記号を出す。
    init(imageData: Data) {
        if let uiImage = UIImage(data: imageData) {
            self.init(uiImage: uiImage)
        } else {
            self.init(systemName: "photo")
        }
    }
}
