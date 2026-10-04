import SwiftData
import SwiftUI

/// 地図にある写真の一覧。リストとグリッドを切り替えて見比べられる(決まったら1つにする)。
/// 行を押すとその写真を開く。並べ替え・削除・編集ができる。
struct PhotoListView: View {
    enum Style: String, CaseIterable, Identifiable {
        case list = "リスト", grid = "グリッド"
        var id: String { rawValue }
    }

    let trip: Trip
    var onSelect: (TripPhoto) -> Void
    var onDeleted: (TripPhoto) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("photoListStyle") private var styleRaw = Style.list.rawValue
    @State private var editing: TripPhoto?
    @State private var photoToDelete: TripPhoto?

    private var style: Style { Style(rawValue: styleRaw) ?? .list }

    var body: some View {
        NavigationStack {
            Group {
                if trip.sortedActivePhotos.isEmpty {
                    ContentUnavailableView("写真はまだありません", systemImage: "photo.on.rectangle")
                } else if style == .list {
                    list
                } else {
                    grid
                }
            }
            .navigationTitle("写真の一覧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Picker("表示", selection: $styleRaw) {
                        ForEach(Style.allCases) { Text($0.rawValue).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
                if style == .list {
                    ToolbarItem(placement: .confirmationAction) { EditButton() }
                }
            }
            .sheet(item: $editing) { EditPhotoView(photo: $0) }
            .confirmationDialog(
                "この写真を削除しますか?",
                isPresented: Binding(get: { photoToDelete != nil }, set: { if !$0 { photoToDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("写真を削除", role: .destructive) {
                    if let photo = photoToDelete { delete(photo) }
                    photoToDelete = nil
                }
            } message: {
                Text("削除した写真は「最近削除した項目」に\(PhotoRetention.days)日間残ります。")
            }
        }
    }

    // MARK: - リスト

    private var list: some View {
        List {
            ForEach(trip.sortedActivePhotos) { photo in
                Button { open(photo) } label: { row(photo) }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) { photoToDelete = photo } label: { Label("削除", systemImage: "trash") }
                    }
                    .swipeActions(edge: .leading) {
                        Button { editing = photo } label: { Label("編集", systemImage: "pencil") }
                            .tint(.blue)
                    }
            }
            .onMove { source, destination in
                var order = trip.sortedActivePhotos
                order.move(fromOffsets: source, toOffset: destination)
                trip.applyOrder(order)
                try? modelContext.save()
            }
        }
    }

    private func row(_ photo: TripPhoto) -> some View {
        HStack(spacing: 12) {
            photo.image
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(photo.title.isEmpty ? "タイトルなし" : photo.title)
                    .foregroundStyle(photo.title.isEmpty ? .secondary : .primary)
                Text(photo.takenAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }

    // MARK: - グリッド

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                ForEach(trip.sortedActivePhotos) { photo in
                    Button { open(photo) } label: {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                photo.image.resizable().scaledToFill()
                            }
                            .clipped()
                    }
                    .buttonStyle(.plain)
                    // ドラッグして別のサムネイルへ落とすと、その位置へ並べ替わる。
                    .draggable(photo.id.uuidString)
                    .dropDestination(for: String.self) { ids, _ in
                        guard let id = ids.first.flatMap(UUID.init(uuidString:)),
                              let dragged = trip.activePhotos.first(where: { $0.id == id }) else { return false }
                        trip.move(dragged, to: photo)
                        try? modelContext.save()
                        return true
                    }
                    .contextMenu {
                        Button { editing = photo } label: { Label("編集", systemImage: "pencil") }
                        Button(role: .destructive) { photoToDelete = photo } label: { Label("削除", systemImage: "trash") }
                    }
                }
            }
        }
    }

    // MARK: - 操作

    private func open(_ photo: TripPhoto) {
        onSelect(photo)
        dismiss()
    }

    private func delete(_ photo: TripPhoto) {
        photo.deletedAt = .now
        try? modelContext.save()
        onDeleted(photo)
    }
}
