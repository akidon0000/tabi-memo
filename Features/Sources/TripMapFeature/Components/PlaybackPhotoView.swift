import SwiftUI

/// 再生中、写真の場所に着いたときに、その写真を拡大して見せる。触れない(再生は止めない)。
struct PlaybackPhotoView: View {
    let image: Image

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            image
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(radius: 20)
                .padding(24)
        }
        .allowsHitTesting(false)
    }
}
