import Domain
import SharedUI
import SwiftUI

/// 一覧の中身。見た目はリスト・カード・グリッドから選べる。操作(開く・名前変更・削除)は呼び出し側に任せる。
struct TripListContent: View {
    let trips: [Trip]
    let style: TripListStyle
    let onOpen: (Trip) -> Void
    let onRename: (Trip) -> Void
    let onRemove: (Trip) -> Void

    var body: some View {
        switch style {
        case .list: list
        case .cards: cards
        case .grid: grid
        }
    }

    private var list: some View {
        List(trips) { trip in
            Button { onOpen(trip) } label: {
                HStack(spacing: 14) {
                    TripCover(trip: trip)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.name).font(.headline).foregroundStyle(.primary)
                        Text(trip.periodText).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.footnote.bold()).foregroundStyle(.tertiary)
                }
            }
            .swipeActions { swipe(trip) }
            .contextMenu { menu(trip) }
        }
        .listStyle(.plain)
    }

    private var cards: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(trips) { trip in
                    Button { onOpen(trip) } label: {
                        TripCover(trip: trip)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .overlay(alignment: .bottomLeading) { caption(trip).padding(16) }
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .contextMenu { menu(trip) }
                }
            }
            .padding(16)
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(trips) { trip in
                    Button { onOpen(trip) } label: {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay { TripCover(trip: trip) }
                            .overlay(alignment: .bottomLeading) { caption(trip).padding(12) }
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .contextMenu { menu(trip) }
                }
            }
            .padding(16)
        }
    }

    /// 写真の上に重ねる名前と期間。読めるように下へ向けて暗くする。
    private func caption(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(trip.name).font(.headline).lineLimit(2)
            Text(trip.periodText).font(.caption)
        }
        .foregroundStyle(.white)
        .shadow(radius: 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .bottom) {
            LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .top, endPoint: .bottom)
                .padding(-40)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func menu(_ trip: Trip) -> some View {
        Button { onRename(trip) } label: { Label("名前を変える", systemImage: "pencil") }
        Button(role: .destructive) { onRemove(trip) } label: { Label("削除", systemImage: "trash") }
    }

    @ViewBuilder
    private func swipe(_ trip: Trip) -> some View {
        Button(role: .destructive) { onRemove(trip) } label: { Label("削除", systemImage: "trash") }
        Button { onRename(trip) } label: { Label("名前", systemImage: "pencil") }.tint(.blue)
    }
}
