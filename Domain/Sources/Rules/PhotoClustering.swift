import Foundation

/// 地図で重なって見える写真を、1つのピンにまとめる。
public enum PhotoClustering {
    /// まとめた写真。1枚だけのこともある。
    public struct Cluster: Identifiable, Hashable, Sendable {
        /// 撮影日時の順。
        public var photos: [Photo]
        /// ピンを立てる位置。いちばん先に撮った写真の位置。
        public var coordinate: Coordinate

        public var id: Photo.ID { photos[0].id }
    }

    /// 縦横それぞれ、しきい値(度)より近い写真を1つにまとめる。
    /// 撮影日時の順に見て、すでにあるまとまりのピンの位置に近ければそこへ入れ、どれにも近くなければ新しいまとまりを作る。
    /// - Parameters:
    ///   - latitudeThreshold: ピン1つぶんの高さに当たる緯度の幅。0 ならまとめない。
    ///   - longitudeThreshold: ピン1つぶんの幅に当たる経度の幅。
    public static func clusters(of photos: [Photo], latitudeThreshold: Double, longitudeThreshold: Double) -> [Cluster] {
        var clusters: [Cluster] = []
        for photo in photos.sorted(by: { $0.takenAt < $1.takenAt }) {
            let index = clusters.firstIndex { cluster in
                abs(cluster.coordinate.latitude - photo.coordinate.latitude) < latitudeThreshold
                    && abs(cluster.coordinate.longitude - photo.coordinate.longitude) < longitudeThreshold
            }
            if let index {
                clusters[index].photos.append(photo)
            } else {
                clusters.append(Cluster(photos: [photo], coordinate: photo.coordinate))
            }
        }
        return clusters
    }
}
