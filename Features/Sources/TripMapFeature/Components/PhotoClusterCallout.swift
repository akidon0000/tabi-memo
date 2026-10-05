import Domain
import SharedUI
import SwiftUI

/// 重なった写真をまとめたピン。1枚ぶんと同じ大きさの正方形に、最大4枚をグリッドで並べる(2枚以上で使う)。
/// 5枚以上なら、4マス目に残りの枚数を出す。
struct PhotoClusterCallout: View {
    let photos: [Photo]
    let action: () -> Void

    private let size: CGFloat = 52
    private let gap: CGFloat = 2

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                grid
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(4)
                    .background(.background, in: RoundedRectangle(cornerRadius: 10))
                CalloutTail()
                    .fill(.background)
                    .frame(width: 14, height: 7)
            }
            .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(photos.count)枚の写真")
    }

    /// 枚数に合わせた並べ方。2枚は左右に半分ずつ、3枚は左に1枚・右に2枚、4枚以上は 2×2。
    @ViewBuilder
    private var grid: some View {
        let half = (size - gap) / 2
        switch photos.count {
        case 2:
            HStack(spacing: gap) {
                cell(0, width: half, height: size)
                cell(1, width: half, height: size)
            }
        case 3:
            HStack(spacing: gap) {
                cell(0, width: half, height: size)
                VStack(spacing: gap) {
                    cell(1, width: half, height: half)
                    cell(2, width: half, height: half)
                }
            }
        default:
            VStack(spacing: gap) {
                HStack(spacing: gap) {
                    cell(0, width: half, height: half)
                    cell(1, width: half, height: half)
                }
                HStack(spacing: gap) {
                    cell(2, width: half, height: half)
                    cell(3, width: half, height: half)
                }
            }
        }
    }

    private func cell(_ index: Int, width: CGFloat, height: CGFloat) -> some View {
        cellView(photos[index], index: index)
            .frame(width: width, height: height)
            .clipped()
    }

    @ViewBuilder
    private func cellView(_ photo: Photo, index: Int) -> some View {
        let image = photo.image.resizable().scaledToFill()
        if index == 3, photos.count > 4 {
            image.overlay {
                Color.black.opacity(0.45)
                Text("+\(photos.count - 3)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
        } else {
            image
        }
    }
}
