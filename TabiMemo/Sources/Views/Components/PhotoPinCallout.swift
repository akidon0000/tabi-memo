import SwiftUI

/// 地図上の吹き出し型サムネイルピン。タップ操作を親から受け取る。
struct PhotoPinCallout: View {
    let photo: TripPhoto
    var isEmphasized: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                thumbnail
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(4)
                    .background(.background, in: RoundedRectangle(cornerRadius: 10))
                CalloutTail()
                    .fill(.background)
                    .frame(width: 14, height: 7)
            }
            .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
            .scaleEffect(isEmphasized ? 1.6 : 1)
            .animation(.spring(duration: 0.35), value: isEmphasized)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let uiImage = UIImage(data: photo.imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Color.secondary.opacity(0.3)
        }
    }
}

/// 吹き出しの下向きの尖り部分。
struct CalloutTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
