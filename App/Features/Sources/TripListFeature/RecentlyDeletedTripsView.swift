import Domain
import SwiftUI

/// 削除したトリップの一覧。保持期間のあいだ、元に戻すか、完全に削除できる。
struct RecentlyDeletedTripsView: View {
    let viewModel: TripListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var tripToErase: Trip?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.removedTrips.isEmpty {
                    ContentUnavailableView("最近削除したトリップはありません", systemImage: "trash")
                } else {
                    List(viewModel.removedTrips) { trip in row(trip) }
                }
            }
            .navigationTitle("最近削除したトリップ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("完了") { dismiss() } }
            }
            .confirmationDialog(
                "このトリップを完全に削除しますか?",
                isPresented: Binding(get: { tripToErase != nil }, set: { if !$0 { tripToErase = nil } }),
                titleVisibility: .visible
            ) {
                Button("完全に削除", role: .destructive) {
                    if let trip = tripToErase { viewModel.deletePermanently(trip) }
                    tripToErase = nil
                }
            } message: {
                Text("写真とメモもすべて消えます。この操作は取り消せません。")
            }
        }
    }

    private func row(_ trip: Trip) -> some View {
        HStack(spacing: 12) {
            TripCover(trip: trip)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name)
                Text(trip.periodText).font(.caption).foregroundStyle(.secondary)
                if let removedAt = trip.removedAt {
                    Text("あと\(TripRetention.daysRemaining(removedAt))日で完全に削除")
                        .font(.caption).foregroundStyle(.red)
                }
                HStack(spacing: 16) {
                    Button("元に戻す") { viewModel.restore(trip) }
                    Button("完全に削除", role: .destructive) { tripToErase = trip }
                }
                .font(.subheadline)
                .buttonStyle(.borderless)
                .padding(.top, 2)
            }
        }
    }
}
