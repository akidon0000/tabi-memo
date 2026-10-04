import SwiftData
import SwiftUI

/// 削除した写真の一覧。保持期間のあいだ、元に戻すか、完全に削除できる。
struct RecentlyDeletedView: View {
    let trip: Trip
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var photoToErase: TripPhoto?

    var body: some View {
        NavigationStack {
            Group {
                if trip.deletedPhotos.isEmpty {
                    ContentUnavailableView("最近取り除いた項目はありません", systemImage: "trash")
                } else {
                    List(trip.deletedPhotos) { photo in
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
                    if let photo = photoToErase {
                        modelContext.delete(photo)
                        try? modelContext.save()
                    }
                    photoToErase = nil
                }
            } message: {
                Text("この操作は取り消せません。")
            }
        }
        .task { trip.purgeExpiredPhotos(in: modelContext) }
    }

    private func row(_ photo: TripPhoto) -> some View {
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
                if let deletedAt = photo.deletedAt {
                    Text("あと\(PhotoRetention.daysRemaining(deletedAt))日で完全に削除")
                        .font(.caption).foregroundStyle(.red)
                }
                HStack(spacing: 16) {
                    Button("元に戻す") {
                        photo.deletedAt = nil
                        try? modelContext.save()
                    }
                    Button("完全に削除", role: .destructive) { photoToErase = photo }
                }
                .font(.subheadline)
                .buttonStyle(.borderless)
                .padding(.top, 2)
            }
        }
    }
}
