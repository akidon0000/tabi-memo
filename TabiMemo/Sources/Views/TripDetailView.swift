import MapKit
import SwiftData
import SwiftUI

struct TripDetailView: View {
    @Bindable var trip: Trip
    @State private var selectedPhoto: TripPhoto?

    var body: some View {
        Map {
            if trip.locationPoints.count > 1 {
                MapPolyline(coordinates: trip.locationPoints
                    .sorted { $0.timestamp < $1.timestamp }
                    .map(\.coordinate))
                    .stroke(Color.accentColor, lineWidth: 3)
            }
            ForEach(trip.photos) { photo in
                Annotation(
                    photo.takenAt.formatted(date: .omitted, time: .shortened),
                    coordinate: photo.coordinate,
                    anchor: .bottom
                ) {
                    PhotoPinCallout(photo: photo) {
                        selectedPhoto = photo
                    }
                }
            }
        }
        .mapStyle(.hybrid())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if trip.isActive {
                    Button("トリップ終了") {
                        trip.endedAt = .now
                    }
                } else {
                    NavigationLink(value: Route.replay(trip)) {
                        Label("リプレイ", systemImage: "play.circle")
                    }
                }
            }
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailSheet(photo: photo)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

/// 写真ピンをタップしたときに開く詳細シート。
/// 写真をヘッダーとして上端いっぱいに敷き、スクロールに応じて視差で動き、引っ張ると伸びる。
private struct PhotoDetailSheet: View {
    let photo: TripPhoto
    @Environment(\.dismiss) private var dismiss

    private let headerHeight: CGFloat = 320

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                VStack(alignment: .leading, spacing: 12) {
                    Text(photo.takenAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.title3.bold())
                    if photo.isLocationManuallyPlaced {
                        Label("位置は手動で指定されました", systemImage: "hand.tap")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.black.opacity(0.45), in: .circle)
            }
            .accessibilityLabel("閉じる")
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
    }

    private var header: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .scrollView).minY
            // 下に引っ張ったら伸ばし、上にスクロールしたら半分の速さで追従させる(視差)。
            let stretch = max(minY, 0)
            let parallax = minY < 0 ? -minY * 0.5 : 0
            Group {
                if let uiImage = UIImage(data: photo.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.secondary.opacity(0.3)
                }
            }
            .frame(width: proxy.size.width, height: headerHeight + stretch)
            .clipped()
            .offset(y: -stretch + parallax)
        }
        .frame(height: headerHeight)
    }
}
