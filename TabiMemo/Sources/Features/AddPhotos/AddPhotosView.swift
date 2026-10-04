import PhotosUI
import SwiftUI

/// 写真の詳細入力モーダル。選んだ枚数ぶんのページを横にめくり、最後にまとめて保存する。
struct AddPhotosView: View {
    @Bindable var viewModel: AddPhotosViewModel
    let items: [PhotosPickerItem]
    /// 閉じるとき。保存したら true、破棄したら false。
    var onFinish: (_ saved: Bool) -> Void

    @State private var confirmDiscard = false
    @State private var isReordering = false

    var body: some View {
        NavigationStack {
            editPages
                .navigationDestination(isPresented: $isReordering) {
                    ReorderView(viewModel: viewModel, onSave: save)
                }
        }
        .interactiveDismissDisabled()
        .task { await viewModel.load(items) }
    }

    private var editPages: some View {
        TabView(selection: $viewModel.currentID) {
            ForEach(viewModel.drafts) { draft in
                DraftPage(draft: draft, viewModel: viewModel)
                    .tag(Optional(draft.id))
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 「1/3」と数字で出すと「次へ」が次の写真へ進むように見えるので、点で表す(横にめくれることも伝わる)。
            ToolbarItem(placement: .principal) {
                if viewModel.isMultiple { PageDots(count: viewModel.drafts.count, current: viewModel.currentIndex) }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button { confirmDiscard = true } label: { Image(systemName: "xmark") }
                    .accessibilityLabel("閉じる")
            }
            ToolbarItem(placement: .confirmationAction) { confirmButton }
        }
        .confirmationDialog("入力した内容を破棄しますか?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("破棄する", role: .destructive) { onFinish(false) }
        }
        .onChange(of: viewModel.currentID) { viewModel.prefetchSuggestions() }
    }

    /// 複数枚のときは、最後のページでも「並べ替えへ」。並べ替えの画面で保存する。
    @ViewBuilder
    private var confirmButton: some View {
        if viewModel.isMultiple {
            Button("並べ替えへ") {
                viewModel.prepareReorder()
                isReordering = true
            }
            .disabled(!viewModel.canSave)
        } else {
            Button("保存", action: save)
                .disabled(!viewModel.canSave)
        }
    }

    private func save() {
        viewModel.save()
        onFinish(true)
    }
}
