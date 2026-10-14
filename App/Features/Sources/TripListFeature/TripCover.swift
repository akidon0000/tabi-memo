import Domain
import SharedUI
import SwiftUI

/// トリップの表紙(最初の写真)。写真が無ければ地図のアイコン。
struct TripCover: View {
    let trip: Trip

    var body: some View {
        if let photo = trip.activePhotos.first {
            photo.image
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Rectangle().fill(.quaternary)
                Image(systemName: "map")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

extension Trip {
    /// 一覧に出す期間。最初と最後の写真が同じ日なら、その日だけ。
    var periodText: String {
        let range = period
        let first = range.lowerBound.formatted(date: .abbreviated, time: .omitted)
        guard !Calendar.current.isDate(range.lowerBound, inSameDayAs: range.upperBound) else { return first }
        return "\(first)〜\(range.upperBound.formatted(date: .abbreviated, time: .omitted))"
    }
}
