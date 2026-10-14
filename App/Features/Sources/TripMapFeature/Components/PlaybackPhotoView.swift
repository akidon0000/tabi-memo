import SwiftUI

/// 再生中、写真の場所に着いたときに、その写真を拡大して見せる。触れない(再生は止めない)。
struct PlaybackPhotoView: View {
    let image: Image

    var body: some View {
        // 画面の縁いっぱい(ステータスバーの裏まで)に広げる。写真は画面を埋めるように拡大し、はみ出す分は切る。
        Color.black
            .overlay { image.resizable().scaledToFill() }
            .clipShape(RoundedRectangle(cornerRadius: 56, style: .continuous))
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}
