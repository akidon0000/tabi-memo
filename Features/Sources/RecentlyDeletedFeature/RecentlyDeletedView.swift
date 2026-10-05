import Domain
import SharedUI
import SwiftUI

/// 取り除いた写真の一覧。保持期間のあいだ、元に戻すか、完全に削除できる。
public struct RecentlyDeletedView: View {
    @State private var viewModel: RecentlyDeletedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var photoToErase: Photo?

    public init(viewModel: RecentlyDeletedViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.photos.isEmpty {
                    ContentUnavailableView("最近取り除いた項目はありません", systemImage: "trash")
                } else {
                    List(viewModel.photos) { photo in
                        row(photo)
                    }
                }
            }
            .navigationTitle("最近取り除いた項目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
            .confirmationDialog(
                "この写真を完全に削除しますか?",
                isPresented: Binding(get: { photoToErase != nil }, set: { if !$0 { photoToErase = nil } }),
                titleVisibility: .visible
            ) {
                Button("完全に削除", role: .destructive) {
                    if let photo = photoToErase { viewModel.deletePermanently(photo) }
                    photoToErase = nil
                }
            } message: {
                Text("この操作は取り消せません。")
            }
        }
        .task { await viewModel.start() }
    }

    private func row(_ photo: Photo) -> some View {
        HStack(spacing: 12) {
            photo.image
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(photo.title.isEmpty ? "タイトルなし" : photo.title)
                    .foregroundStyle(photo.title.isEmpty ? .secondary : .primary)
                Text(photo.takenAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
                if let removedAt = photo.removedAt {
                    Text("あと\(PhotoRetention.daysRemaining(removedAt))日で完全に削除")
                        .font(.caption).foregroundStyle(.red)
                }
                HStack(spacing: 16) {
                    Button("元に戻す") { viewModel.restore(photo) }
                    Button("完全に削除", role: .destructive) { photoToErase = photo }
                }
                .font(.subheadline)
                .buttonStyle(.borderless)
                .padding(.top, 2)
            }
        }
    }
}
