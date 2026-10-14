import Domain
import SharedUI
import SwiftUI
import TripMapFeature

/// アプリの最初の画面。トリップを一覧し、選ぶと地図画面へ進む。作る・名前を変える・削除する・戻すもここから行う。
public struct TripListView: View {
    @State private var viewModel: TripListViewModel
    /// 地図画面の作り方。組み立ては App が行い、この画面は作り方を知らない。
    private let makeTripMap: (Trip.ID) -> TripMapView

    @AppStorage(AppearanceKey.tripListStyle) private var style = TripListStyle.list
    @AppStorage(AppearanceKey.tripListOrder) private var order = TripListOrder.newest
    @State private var path: [Trip.ID] = []
    @State private var naming: Naming?
    @State private var nameText = ""
    @State private var showRecentlyDeleted = false
    @State private var showSettings = false

    /// 名前を入れる操作。新しく作るか、既存の名前を変えるか。
    private enum Naming: Identifiable {
        case create
        case rename(Trip)
        var id: String {
            switch self {
            case .create: "create"
            case .rename(let trip): trip.id.uuidString
            }
        }
    }

    public init(viewModel: TripListViewModel, makeTripMap: @escaping (Trip.ID) -> TripMapView) {
        _viewModel = State(initialValue: viewModel)
        self.makeTripMap = makeTripMap
    }

    public var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("トリップ")
                .toolbar { toolbar }
                .navigationDestination(for: Trip.ID.self) { makeTripMap($0) }
        }
        .task { await viewModel.start() }
        .alert(namingTitle, isPresented: isNaming) {
            TextField("名前", text: $nameText)
            Button("キャンセル", role: .cancel) {}
            Button(namingButton, action: commitNaming)
        }
        .sheet(isPresented: $showRecentlyDeleted) { RecentlyDeletedTripsView(viewModel: viewModel) }
        .sheet(isPresented: $showSettings) { AppearanceSettingsView() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.trips.isEmpty {
            if viewModel.hasLoaded {
                ContentUnavailableView {
                    Label("トリップがありません", systemImage: "map")
                } description: {
                    Text("右上の「+」で、最初のトリップを作ります。")
                }
            }
        } else {
            TripListContent(
                trips: viewModel.sortedTrips(order),
                style: style,
                onOpen: { path.append($0.id) },
                onRename: { beginNaming(.rename($0)) },
                onRemove: { viewModel.remove($0) }
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Button { showRecentlyDeleted = true } label: { Label("最近削除したトリップ", systemImage: "trash") }
                Button { showSettings = true } label: { Label("見た目の設定", systemImage: "slider.horizontal.3") }
            } label: {
                Image(systemName: "ellipsis")
            }
            .accessibilityLabel("メニュー")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { beginNaming(.create) } label: { Image(systemName: "plus") }
                .accessibilityLabel("新しいトリップ")
        }
    }

    // MARK: - 名前を入れる

    private var namingTitle: String {
        if case .rename = naming { "名前を変える" } else { "新しいトリップ" }
    }

    private var namingButton: String {
        if case .rename = naming { "変更" } else { "作成" }
    }

    private var isNaming: Binding<Bool> {
        Binding(get: { naming != nil }, set: { if !$0 { naming = nil } })
    }

    private func beginNaming(_ kind: Naming) {
        nameText = if case .rename(let trip) = kind { trip.name } else { "" }
        naming = kind
    }

    private func commitNaming() {
        switch naming {
        case .create:
            if let id = viewModel.create(name: nameText) { path.append(id) }
        case .rename(let trip):
            viewModel.rename(trip, to: nameText)
        case nil:
            break
        }
        naming = nil
    }
}
