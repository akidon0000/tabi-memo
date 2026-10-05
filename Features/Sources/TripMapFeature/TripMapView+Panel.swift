import AddPhotosFeature
import Domain
import EditPhotoFeature
import PhotoListFeature
import RecentlyDeletedFeature
import SharedUI
import SwiftUI

extension TripMapView {
    /// 写真を選んでいるときは下部パネル、選んでいないときは右下の追加ボタン。
    var panelLayer: some View {
        ZStack {
            if viewModel.route.isEditing {
                EmptyView()
            } else if let photo = viewModel.selectedPhoto {
                photoPanel(photo)
                    .transition(.move(edge: .bottom))
            } else {
                addPhotoButton
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .animation(.spring(duration: 0.4), value: viewModel.selectedPhoto == nil)
    }

    private func photoPanel(_ photo: Photo) -> some View {
        CustomSheetView(
            config: $sheetConfig,
            title: photo.takenAt.formatted(date: .abbreviated, time: .shortened),
            caption: caption(photo),
            headerImage: photo.image,
            headerAspectRatio: photo.aspectRatio,
            onAdd: addPhoto,
            onImageTap: { zoomedPhoto = photo },
            canPage: { viewModel.neighbor($0, of: photo) != nil },
            onPage: { step in
                if let next = viewModel.neighbor(step, of: photo) { open(next) }
            },
            neighbor: { step in
                viewModel.neighbor(step, of: photo).map(snapshot)
            },
            onEdit: { editingPhoto = photo },
            onDelete: { confirmRemove = true },
            onFullProgressChange: { panelFullProgress = $0 },
            content: { PhotoMemoView(photo: photo) }
        )
    }

    private func caption(_ photo: Photo) -> String {
        photo.isLocationManuallyPlaced ? "位置は手動で指定されました" : ""
    }

    private func snapshot(_ photo: Photo) -> PageSnapshot {
        PageSnapshot(
            title: photo.takenAt.formatted(date: .abbreviated, time: .shortened),
            caption: caption(photo),
            image: photo.image,
            aspectRatio: photo.aspectRatio,
            content: AnyView(PhotoMemoView(photo: photo))
        )
    }

    /// 右上に常に出す「…」(44pt)。
    var moreMenu: some View {
        Menu {
            Button { showPhotoList = true } label: {
                Label("写真の一覧", systemImage: "list.bullet")
            }
            Button { showRecentlyDeleted = true } label: {
                Label("最近取り除いた項目", systemImage: "trash")
            }
            Divider()
            Button { viewModel.route.isEditing = true } label: {
                Label("経路を編集", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
            }
            Toggle("経路の編集中は地図を動かさない", isOn: $routeEditLocksMap)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        // 全開に向かうほど薄くして消し、同じ位置にパネルの閉じるボタンを出す。
        .opacity(viewModel.selectedPhoto == nil ? 1 : 1 - panelFullProgress)
        .allowsHitTesting(panelFullProgress < 0.5)
        .accessibilityLabel("メニュー")
    }

    /// パネルがないときの、右下の円形の追加ボタン。パネルのコンパクト時のボタンと同じ位置に置く。
    private var addPhotoButton: some View {
        Button(action: addPhoto) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 64, height: 64)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("写真を追加")
        .padding(.trailing, 16)
        .padding(.bottom, 28)
    }
}
