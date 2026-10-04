import Domain
import SwiftUI

/// 写真に添えるタイトルとメモ。パネルの中身(写真の下)に出て、写真と一緒にスクロールする。
/// 読むだけで、書き換えはペンの編集から。
struct PhotoMemoView: View {
    let photo: Photo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !photo.title.isEmpty {
                Text(photo.title)
                    .font(.title3.bold())
            }
            Text("メモ")
                .font(.headline)
            Text(photo.memo.isEmpty ? "メモはありません" : photo.memo)
                .foregroundStyle(photo.memo.isEmpty ? .secondary : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        // 写真が上へ流れきるまでスクロールできるよう、下に余白を取る。
        .padding(.bottom, 360)
    }
}
