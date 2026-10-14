import SwiftUI

/// 「+」を押したときの、カメラで撮る・ライブラリから選ぶの選択(大きな2ボタンの小さなシート)。
struct AddChoiceSheet: View {
    let onChoose: (TripMapView.AddSource) -> Void

    var body: some View {
        HStack(spacing: 16) {
            choice("camera.fill", "カメラで撮る", .camera)
            choice("photo.on.rectangle", "ライブラリから選ぶ", .library)
        }
        .padding(20)
    }

    private func choice(_ symbol: String, _ title: String, _ source: TripMapView.AddSource) -> some View {
        Button { onChoose(source) } label: {
            VStack(spacing: 10) {
                Image(systemName: symbol).font(.system(size: 30))
                Text(title).font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity, minHeight: 120)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.roundedRectangle(radius: 24))
    }
}
