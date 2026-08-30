import SwiftUI

/// MapKitのカメラが軌跡をなぞりながら写真ピンで一時停止する、アプリの核となる機能。
/// カメラ演出・ペーシングアルゴリズム(時間ベース/密度ベース)・動画エクスポートは未実装。
struct ReplayView: View {
    let trip: Trip

    var body: some View {
        ContentUnavailableView(
            "リプレイは準備中です",
            systemImage: "play.circle",
            description: Text("\(trip.name) のカメラ演出は今後実装します")
        )
        .navigationTitle("リプレイ")
    }
}
