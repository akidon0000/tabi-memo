import Domain
import SharedUI
import SwiftUI

/// 入力ページの項目: 日時・場所・タイトル・メモ。AI の提案は、タイトルとメモの入力欄に薄い文字で出し、「適用」で入れる。
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
                fieldLabel("タイトル", suggestion: suggestion?.title, current: draft.title) { draft.title = $0 }
                TextField("タイトル", text: $draft.title, prompt: prompt(suggestion?.title, loading: "AI がタイトルを考えています…", empty: "タイトル"))
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("メモ", suggestion: suggestion?.description, current: draft.memo) { draft.memo = $0 }
                TextField("メモ", text: $draft.memo, prompt: prompt(suggestion?.description, loading: "AI がメモを考えています…", empty: "メモを書く"), axis: .vertical)
                    .lineLimit(4...)
                    .textFieldStyle(.roundedBorder)
            }
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

    /// AI の提案。できていなければ nil。
    private var suggestion: PhotoSuggestion? {
        if case .ready(let suggestion) = draft.suggestion { suggestion } else { nil }
    }

    /// 入力欄が空のときに出す薄い文字。AI の提案があればそれを、作っている間はその旨を出す。
    private func prompt(_ suggested: String?, loading: String, empty: String) -> Text {
        if let suggested { return Text(suggested) }
        if case .loading = draft.suggestion { return Text(loading) }
        return Text(empty)
    }

    /// 項目名と、AI の提案を入力欄に入れる「適用」ボタン。提案があり、まだ入れていないときだけボタンを出す。
    private func fieldLabel(_ title: String, suggestion: String?, current: String, apply: @escaping (String) -> Void) -> some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            if let suggestion, suggestion != current {
                Button { apply(suggestion) } label: {
                    Label("適用", systemImage: "sparkles")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("AI の\(title)の案を入れる")
            }
        }
    }
}
