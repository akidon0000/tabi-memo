import SwiftUI

/// 1枚ぶんの入力ページ。写真と、日時・場所・タイトル・メモ・AI の提案。
struct DraftPage: View {
    @Bindable var draft: PhotoDraft
    let viewModel: AddPhotosViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                photo
                if draft.loadFailed {
                    failedNotice
                } else if draft.imageData != nil {
                    DraftFields(draft: draft, viewModel: viewModel)
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
                .overlay { pageArrows }
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(.quaternary)
                .frame(height: 200)
                .overlay { if !draft.loadFailed { ProgressView() } }
        }
    }

    /// 写真の左右に薄く出す矢印。横にめくれることを伝える。押しても前後へ移れる。
    private var pageArrows: some View {
        let index = viewModel.drafts.firstIndex { $0.id == draft.id } ?? 0
        return HStack {
            if index > 0 { arrow("chevron.left", to: index - 1) }
            Spacer()
            if index < viewModel.drafts.count - 1 { arrow("chevron.right", to: index + 1) }
        }
        .padding(.horizontal, 8)
    }

    private func arrow(_ name: String, to index: Int) -> some View {
        Button {
            withAnimation { viewModel.currentID = viewModel.drafts[index].id }
        } label: {
            Image(systemName: name)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .shadow(color: .black.opacity(0.35), radius: 3)
                .frame(width: 44, height: 64)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name == "chevron.left" ? "前の写真" : "次の写真")
    }

    private var failedNotice: some View {
        VStack(spacing: 12) {
            Text("この写真を読み込めませんでした")
            Button("この写真を外す", role: .destructive) { viewModel.remove(draft) }
        }
        .frame(maxWidth: .infinity)
    }
}
