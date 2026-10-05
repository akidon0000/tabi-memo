import SharedUI
import SwiftUI

/// 保存前に写真の順番を並べ替える画面。並びは日時の割り当てとして保存される。
struct ReorderView: View {
    @Bindable var viewModel: AddPhotosViewModel
    var onSave: () -> Void

    var body: some View {
        List {
            Section {
                ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                    row(entry, date: viewModel.assignedDates[index])
                }
                .onMove { viewModel.entries.move(fromOffsets: $0, toOffset: $1) }
            } footer: {
                Text("地図にすでにある写真も含めて、長押しして動かすと並べ替えられます。日時は、いまの日時を古い順に並べ直して割り当てます。")
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("順番")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("すべて保存", action: onSave)
            }
        }
    }

    private func row(_ entry: ReorderEntry, date: Date) -> some View {
        HStack(spacing: 12) {
            if let data = entry.imageData {
                Image(imageData: data)
                    .resizable().scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.title.isEmpty ? "タイトルなし" : entry.title)
                        .foregroundStyle(entry.title.isEmpty ? .secondary : .primary)
                    if entry.isNew {
                        Text("追加").font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(.tint.opacity(0.2), in: Capsule())
                    }
                }
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
