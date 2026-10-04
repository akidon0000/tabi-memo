import SwiftUI

/// 入力ページの項目: 日時・場所・タイトル・メモ・AI の提案。
struct DraftFields: View {
    @Bindable var draft: PhotoDraft
    let viewModel: AddPhotosViewModel
    @State private var showLocationPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                DatePicker("日時", selection: $draft.takenAt)
                if !draft.hasMetadataDate {
                    Text("写真に撮影日時が無かったので、現在時刻を入れています")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            locationRow

            VStack(alignment: .leading, spacing: 6) {
                Text("タイトル").font(.headline)
                TextField("タイトル", text: $draft.title)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("メモ").font(.headline)
                TextField("メモを書く", text: $draft.memo, axis: .vertical)
                    .lineLimit(4...)
                    .textFieldStyle(.roundedBorder)
            }
            suggestionBox
        }
    }

    private var locationRow: some View {
        Button { showLocationPicker = true } label: {
            HStack {
                Label("場所", systemImage: "mappin.and.ellipse")
                Spacer()
                if let coordinate = draft.coordinate {
                    Text(draft.isLocationManual ? "地図で指定済み" : "写真の位置情報")
                        .foregroundStyle(.secondary)
                        .accessibilityHint(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
                } else {
                    Text("未設定(タップして指定)").foregroundStyle(.red)
                }
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showLocationPicker) {
            LocationPinPicker(initialCenter: viewModel.initialCenter(for: draft), current: draft.coordinate) {
                draft.coordinate = $0
                draft.isLocationManual = true
            }
        }
    }

    @ViewBuilder private var suggestionBox: some View {
        switch draft.suggestion {
        case .idle, .unavailable:
            EmptyView()
        case .loading:
            Label("タイトルと解説を考えています…", systemImage: "sparkles")
                .font(.footnote).foregroundStyle(.secondary)
        case .ready(let suggestion):
            VStack(alignment: .leading, spacing: 8) {
                Label("AI の提案", systemImage: "sparkles").font(.headline)
                Text(suggestion.title).font(.subheadline.bold())
                Text(suggestion.description).font(.subheadline)
                Button("提案を使う") {
                    draft.title = suggestion.title
                    draft.memo = suggestion.description
                }
                .buttonStyle(.glass)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
