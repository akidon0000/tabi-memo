import MapKit
import PhotosUI
import SwiftData
import SwiftUI

/// 写真の詳細入力モーダル。選んだ枚数ぶんのページを横にめくり、最後にまとめて保存する。
struct AddPhotosView: View {
    @Bindable var model: AddPhotosModel
    let items: [PhotosPickerItem]
    let trip: Trip
    var onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var confirmDiscard = false
    @State private var isReordering = false

    private var isMultiple: Bool { model.drafts.count > 1 }

    var body: some View {
        NavigationStack {
            editPages
                .navigationDestination(isPresented: $isReordering) {
                    ReorderView(model: model) {
                        model.save(into: trip, context: modelContext)
                        onFinish()
                    }
                }
        }
        .interactiveDismissDisabled()
        .task { await model.load(items) }
    }

    private var editPages: some View {
        TabView(selection: $model.currentID) {
            ForEach(model.drafts) { draft in
                DraftPage(draft: draft, model: model)
                    .tag(Optional(draft.id))
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 「1/3」と数字で出すと「次へ」が次の写真へ進むように見えるので、点で表す(横にめくれることも伝わる)。
            ToolbarItem(placement: .principal) {
                if isMultiple { PageDots(count: model.drafts.count, current: model.currentIndex) }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button { confirmDiscard = true } label: { Image(systemName: "xmark") }
                    .accessibilityLabel("閉じる")
            }
            ToolbarItem(placement: .confirmationAction) {
                // 複数枚のときは、最後のページでも「並べ替えへ」。並べ替えの画面で保存する。
                if isMultiple {
                    Button("並べ替えへ") {
                        // 並べ替えの最初の並びは日時の順にする(動かすまで日時が変わらないように)。
                        model.sortByDate()
                        isReordering = true
                    }
                        .disabled(!model.canSave)
                } else {
                    Button("保存") {
                        model.save(into: trip, context: modelContext)
                        onFinish()
                    }
                    .disabled(!model.canSave)
                }
            }
        }
        .confirmationDialog("入力した内容を破棄しますか?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("破棄する", role: .destructive, action: onFinish)
        }
        .onChange(of: model.currentID) { model.prefetchSuggestions() }
    }
}

private struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color.primary : Color.secondary.opacity(0.35))
                    .frame(width: 8, height: 8)
            }
        }
        .animation(.easeOut(duration: 0.2), value: current)
        .accessibilityElement()
        .accessibilityLabel("\(current + 1) / \(count)")
    }
}

/// 保存前に写真の順番を並べ替える画面。並びは日時の割り当てとして保存される。
private struct ReorderView: View {
    @Bindable var model: AddPhotosModel
    var onSave: () -> Void

    var body: some View {
        List {
            Section {
                ForEach(Array(model.drafts.enumerated()), id: \.element.id) { index, draft in
                    HStack(spacing: 12) {
                        thumbnail(draft)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(draft.title.isEmpty ? "タイトルなし" : draft.title)
                                .foregroundStyle(draft.title.isEmpty ? .secondary : .primary)
                            Text(model.assignedDates[index].formatted(date: .abbreviated, time: .shortened))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .onMove { model.drafts.move(fromOffsets: $0, toOffset: $1) }
            } footer: {
                Text("長押しして動かすと並べ替えられます。日時は、いまの日時を古い順に並べ直して割り当てます。")
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

    @ViewBuilder private func thumbnail(_ draft: PhotoDraft) -> some View {
        if let data = draft.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable().scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

private struct DraftPage: View {
    @Bindable var draft: PhotoDraft
    let model: AddPhotosModel
    @State private var showLocationPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                photo
                if draft.loadFailed {
                    failedNotice
                } else if draft.imageData != nil {
                    fields
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder private var photo: some View {
        if let data = draft.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 280)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .frame(maxWidth: .infinity)
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(.quaternary)
                .frame(height: 200)
                .overlay { if !draft.loadFailed { ProgressView() } }
        }
    }

    private var failedNotice: some View {
        VStack(spacing: 12) {
            Text("この写真を読み込めませんでした")
            Button("この写真を外す", role: .destructive) { model.remove(draft) }
        }
        .frame(maxWidth: .infinity)
    }

    private var fields: some View {
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
            LocationPinPicker(initialCenter: model.initialCenter(for: draft), current: draft.coordinate) {
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
